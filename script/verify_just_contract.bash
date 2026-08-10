#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -z "${SCRIPT_DIR}" || ! -d "${SCRIPT_DIR}" ]]; then
  echo "error: failed to resolve the verifier directory" >&2
  exit 2
fi
readonly SCRIPT_DIR

REPOSITORY_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
if [[ -z "${REPOSITORY_ROOT}" || ! -e "${REPOSITORY_ROOT}/.git" ]]; then
  echo "error: failed to resolve the repository root" >&2
  exit 2
fi
readonly REPOSITORY_ROOT

TEMPORARY_ROOT="$(mktemp -d)"
if [[ -z "${TEMPORARY_ROOT}" || ! -d "${TEMPORARY_ROOT}" ]]; then
  echo "error: failed to create the verifier workspace" >&2
  exit 2
fi
readonly TEMPORARY_ROOT

cleanup() {
  rm -rf -- "${TEMPORARY_ROOT}"
}
trap cleanup EXIT

cd "${REPOSITORY_ROOT}"

nul_list_contains() {
  local needle="$1"
  local list_path="$2"
  local candidate

  while IFS= read -r -d '' candidate; do
    if [[ "${candidate}" == "${needle}" ]]; then
      return 0
    fi
  done < "${list_path}"
  return 1
}

for tool in git just python3; do
  if ! command -v "${tool}" >/dev/null 2>&1; then
    echo "error: required contract tool is unavailable: ${tool}" >&2
    exit 2
  fi
done

INITIAL_UNTRACKED_LIST="${TEMPORARY_ROOT}/initial-untracked-paths"
readonly INITIAL_UNTRACKED_LIST
git ls-files -z --others --exclude-standard > "${INITIAL_UNTRACKED_LIST}"

INITIAL_RAW_LOG_LIST="${TEMPORARY_ROOT}/initial-raw-log-paths"
readonly INITIAL_RAW_LOG_LIST
find . -type d \( -name .git -o -name .build \) -prune -o \
  -type f -name '*.log' -print0 > "${INITIAL_RAW_LOG_LIST}"

INITIAL_TEST_LOGS_PRESENT=false
if [[ -d .test-logs ]]; then
  INITIAL_TEST_LOGS_PRESENT=true
fi
readonly INITIAL_TEST_LOGS_PRESENT

REAL_PYTHON3="$(command -v python3)"
if [[ -z "${REAL_PYTHON3}" || ! -x "${REAL_PYTHON3}" ]]; then
  echo "error: failed to resolve the real Python executable" >&2
  exit 2
fi
readonly REAL_PYTHON3

readonly REQUIRED_RECIPES=(
  build
  pre-commit
  verify-just-contract
  test-domain
  test-data
  test-app
  test-app-runtime
  test-pr
  test-all
  ui-screenshots
)

RECIPE_SUMMARY="$(just --summary)"
if [[ -z "${RECIPE_SUMMARY}" ]]; then
  echo "error: just returned an empty recipe summary" >&2
  exit 1
fi
readonly RECIPE_SUMMARY

for recipe in "${REQUIRED_RECIPES[@]}"; do
  if [[ " ${RECIPE_SUMMARY} " != *" ${recipe} "* ]]; then
    echo "error: canonical recipe is missing: ${recipe}" >&2
    exit 1
  fi
done

JUSTFILE_SOURCE="$(<justfile)"
if [[ -z "${JUSTFILE_SOURCE}" ]]; then
  echo "error: justfile is empty" >&2
  exit 1
fi
readonly JUSTFILE_SOURCE

if [[ "${JUSTFILE_SOURCE}" == *".test-logs"* || \
  "${JUSTFILE_SOURCE}" == *"clean-logs"* || \
  "${JUSTFILE_SOURCE}" == *"tee"* ]]; then
  echo "error: justfile reintroduced a repo-local raw log contract" >&2
  exit 1
fi

PRE_COMMIT_RECIPE="$(just --show pre-commit)"
readonly PRE_COMMIT_RECIPE

normalize_recipe_source() {
  local source="$1"
  local line
  local trimmed
  local normalized=""

  while IFS= read -r line || [[ -n "${line}" ]]; do
    trimmed="${line#"${line%%[![:space:]]*}"}"
    if [[ -z "${trimmed}" || "${trimmed}" == \#* ]]; then
      continue
    fi

    if [[ -n "${normalized}" ]]; then
      normalized+=$'\n'
    fi
    normalized+="${trimmed}"
  done <<< "${source}"

  printf '%s' "${normalized}"
}

NORMALIZED_PRE_COMMIT_RECIPE="$(normalize_recipe_source "${PRE_COMMIT_RECIPE}")"
readonly NORMALIZED_PRE_COMMIT_RECIPE
if [[ "${NORMALIZED_PRE_COMMIT_RECIPE}" != $'pre-commit:\n@script/run_swift_quality_checks.bash\n@just verify-just-contract' ]]; then
  echo "error: pre-commit must run quality checks and the just contract verifier" >&2
  exit 1
fi

VERIFY_RECIPE="$(just --show verify-just-contract)"
readonly VERIFY_RECIPE
NORMALIZED_VERIFY_RECIPE="$(normalize_recipe_source "${VERIFY_RECIPE}")"
readonly NORMALIZED_VERIFY_RECIPE
if [[ "${NORMALIZED_VERIFY_RECIPE}" != $'verify-just-contract:\n@script/verify_just_contract.bash' ]]; then
  echo "error: verify-just-contract must invoke the repo-local verifier" >&2
  exit 1
fi

TEST_PR_RECIPE="$(just --show test-pr)"
readonly TEST_PR_RECIPE
NORMALIZED_TEST_PR_RECIPE="$(normalize_recipe_source "${TEST_PR_RECIPE}")"
readonly NORMALIZED_TEST_PR_RECIPE
if [[ "${NORMALIZED_TEST_PR_RECIPE}" != "test-pr: pre-commit build test-domain test-data" ]]; then
  echo "error: test-pr must aggregate only the certificate/provisioning-free PR gates" >&2
  exit 1
fi

TEST_ALL_RECIPE="$(just --show test-all)"
readonly TEST_ALL_RECIPE
NORMALIZED_TEST_ALL_RECIPE="$(normalize_recipe_source "${TEST_ALL_RECIPE}")"
readonly NORMALIZED_TEST_ALL_RECIPE
if [[ "${NORMALIZED_TEST_ALL_RECIPE}" != "test-all: test-pr test-app test-app-runtime" ]]; then
  echo "error: test-all must add the signed app and runtime lanes to test-pr" >&2
  exit 1
fi

BUILD_RECIPE="$(just --show build)"
readonly BUILD_RECIPE
if [[ "${BUILD_RECIPE}" != *"CODE_SIGNING_ALLOWED=NO"* || \
  "${BUILD_RECIPE}" != *"CODE_SIGNING_REQUIRED=NO"* ]]; then
  echo "error: build is not certificate/provisioning-free" >&2
  exit 1
fi

if [[ "${BUILD_RECIPE}" != *"generic/platform=macOS"* || \
  "${BUILD_RECIPE}" != *'-derivedDataPath "${derived_data_path}"'* || \
  "${BUILD_RECIPE}" != *"prepare_build_artifacts.bash prepare-directory"* ]]; then
  echo "error: build does not use the validated generic macOS artifact path" >&2
  exit 1
fi

for recipe in test-app test-app-runtime; do
  recipe_source="$(just --show "${recipe}")"
  if [[ "${recipe_source}" == *"CODE_SIGNING_ALLOWED=NO"* || \
    "${recipe_source}" == *"CODE_SIGNING_REQUIRED=NO"* ]]; then
    echo "error: ${recipe} must remain a signed runnable lane" >&2
    exit 1
  fi

  if [[ "${recipe_source}" != *"prepare-result"* || \
    "${recipe_source}" != *"finalize-result"* || \
    "${recipe_source}" != *'-resultBundlePath "${result_bundle_path}"'* ]]; then
    echo "error: ${recipe} does not preserve a validated xcresult bundle" >&2
    exit 1
  fi
done

SCREENSHOT_RECIPE="$(just --show ui-screenshots)"
readonly SCREENSHOT_RECIPE
for required_fragment in \
  "prepare-result" \
  "finalize-result" \
  "xcrun xcresulttool export attachments" \
  "script/rename_screenshots.py"; do
  if [[ "${SCREENSHOT_RECIPE}" != *"${required_fragment}"* ]]; then
    echo "error: ui-screenshots is missing pipeline step: ${required_fragment}" >&2
    exit 1
  fi
done

mkdir -p -- "${TEMPORARY_ROOT}/bin"

printf '%s\n' \
  '#!/bin/bash' \
  'set -euo pipefail' \
  'derived_data_path=""' \
  'result_bundle_path=""' \
  'found_test_argument_one=false' \
  'found_test_argument_two=false' \
  'screen_test_argument_count=0' \
  'found_unexpected_screen_argument=false' \
  'for argument in "$@"; do' \
  '  if [[ -n "${TODOMATE_EXPECT_TEST_ARGUMENT_ONE:-}" && "${argument}" == "${TODOMATE_EXPECT_TEST_ARGUMENT_ONE}" ]]; then found_test_argument_one=true; fi' \
  '  if [[ -n "${TODOMATE_EXPECT_TEST_ARGUMENT_TWO:-}" && "${argument}" == "${TODOMATE_EXPECT_TEST_ARGUMENT_TWO}" ]]; then found_test_argument_two=true; fi' \
  '  case "${argument}" in' \
  '    -only-testing:TodoMateUITests/ScreenshotTests*)' \
  '      screen_test_argument_count=$((screen_test_argument_count + 1))' \
  '      if [[ "${argument}" != "${TODOMATE_EXPECT_TEST_ARGUMENT_ONE:-}" && "${argument}" != "${TODOMATE_EXPECT_TEST_ARGUMENT_TWO:-}" ]]; then found_unexpected_screen_argument=true; fi' \
  '      ;;' \
  '  esac' \
  'done' \
  'while [[ "$#" -gt 0 ]]; do' \
  '  case "$1" in' \
  '    -derivedDataPath) shift; derived_data_path="${1:-}" ;;' \
  '    -resultBundlePath) shift; result_bundle_path="${1:-}" ;;' \
  '  esac' \
  '  shift || true' \
  'done' \
  'if [[ -n "${TODOMATE_EXPECT_DERIVED_DATA_PATH:-}" && "${derived_data_path}" != "${TODOMATE_EXPECT_DERIVED_DATA_PATH}" ]]; then exit 43; fi' \
  'if [[ -n "${TODOMATE_EXPECT_RESULT_BUNDLE_PATH:-}" && "${result_bundle_path}" != "${TODOMATE_EXPECT_RESULT_BUNDLE_PATH}" ]]; then exit 44; fi' \
  'if [[ -n "${TODOMATE_EXPECT_TEST_ARGUMENT_ONE:-}" && "${found_test_argument_one}" != true ]]; then exit 46; fi' \
  'if [[ -n "${TODOMATE_EXPECT_TEST_ARGUMENT_TWO:-}" && "${found_test_argument_two}" != true ]]; then exit 47; fi' \
  'if [[ "${TODOMATE_EXPECT_EXACT_SCREEN_ARGUMENTS:-}" == "true" && ( "${screen_test_argument_count}" -ne 2 || "${found_unexpected_screen_argument}" == true ) ]]; then exit 48; fi' \
  'if [[ "${TODOMATE_FAKE_FAILURE:-}" == "xcodebuild-no-bundle" ]]; then exit 42; fi' \
  'if [[ -n "${result_bundle_path}" ]]; then mkdir -p -- "${result_bundle_path}"; touch -- "${result_bundle_path}/Info.plist"; fi' \
  'if [[ "${TODOMATE_FAKE_FAILURE:-}" == "xcodebuild" ]]; then exit 42; fi' \
  'exit 0' \
  > "${TEMPORARY_ROOT}/bin/xcodebuild"

printf '%s\n' \
  '#!/bin/bash' \
  'if [[ "${TODOMATE_FAKE_FAILURE:-}" == "swift" ]]; then exit 42; fi' \
  'exit 0' \
  > "${TEMPORARY_ROOT}/bin/swift"

printf '%s\n' \
  '#!/bin/bash' \
  'cat' \
  'if [[ "${TODOMATE_FAKE_FAILURE:-}" == "xcbeautify" ]]; then exit 42; fi' \
  'exit 0' \
  > "${TEMPORARY_ROOT}/bin/xcbeautify"

printf '%s\n' \
  '#!/bin/bash' \
  'set -euo pipefail' \
  'if [[ "${TODOMATE_FAKE_FAILURE:-}" == "xcrun" ]]; then exit 42; fi' \
  'manifest_path=""' \
  'output_path=""' \
  'while [[ "$#" -gt 0 ]]; do' \
  '  if [[ "$1" == "--manifest" ]]; then shift; manifest_path="${1:-}"; fi' \
  '  if [[ "$1" == "--output-path" ]]; then shift; output_path="${1:-}"; fi' \
  '  shift || true' \
  'done' \
  'if [[ -n "${TODOMATE_EXPECT_SCREENSHOT_MANIFEST:-}" && "${manifest_path}" != "${TODOMATE_EXPECT_SCREENSHOT_MANIFEST}" ]]; then exit 49; fi' \
  'if [[ -n "${TODOMATE_EXPECT_SCREENSHOT_OUTPUT_PATH:-}" && "${output_path}" != "${TODOMATE_EXPECT_SCREENSHOT_OUTPUT_PATH}" ]]; then exit 50; fi' \
  'if [[ -n "${manifest_path}" && -e "${manifest_path}" ]]; then exit 52; fi' \
  'if [[ -n "${manifest_path}" ]]; then printf "%s\n" "[]" > "${manifest_path}"; fi' \
  'exit 0' \
  > "${TEMPORARY_ROOT}/bin/xcrun"

printf '%s\n' \
  '#!/bin/bash' \
  'set -euo pipefail' \
  'case "${1:-}" in' \
  '  *generate_screenshot_test_args.py)' \
  '    if [[ "${TODOMATE_FAKE_FAILURE:-}" == "python3-generate" ]]; then exit 42; fi' \
    '    ;;' \
  '  *rename_screenshots.py)' \
  '    if [[ "${TODOMATE_FAKE_FAILURE:-}" == "python3-rename" ]]; then exit 42; fi' \
  '    if [[ -n "${TODOMATE_EXPECT_SCREENSHOT_RENAME_PATH:-}" && "${2:-}" != "${TODOMATE_EXPECT_SCREENSHOT_RENAME_PATH}" ]]; then exit 51; fi' \
  '    ;;' \
  '  *) exit 45 ;;' \
  'esac' \
  'exec "${TODOMATE_REAL_PYTHON3:?}" "$@"' \
  > "${TEMPORARY_ROOT}/bin/python3"

printf '%s\n' \
  '#!/bin/bash' \
  'set -euo pipefail' \
  'file_list=""' \
  'while [[ "$#" -gt 0 ]]; do' \
  '  if [[ "$1" == "--filelist" ]]; then shift; file_list="${1:-}"; fi' \
  '  shift || true' \
  'done' \
  'if [[ -n "${TODOMATE_FAKE_FILE_LIST:-}" && -n "${file_list}" ]]; then cp -- "${file_list}" "${TODOMATE_FAKE_FILE_LIST}"; fi' \
  'exit 0' \
  > "${TEMPORARY_ROOT}/bin/swiftformat"

printf '%s\n' '#!/bin/bash' 'exit 0' > "${TEMPORARY_ROOT}/bin/swiftlint"

chmod +x \
  "${TEMPORARY_ROOT}/bin/xcodebuild" \
  "${TEMPORARY_ROOT}/bin/swift" \
  "${TEMPORARY_ROOT}/bin/xcbeautify" \
  "${TEMPORARY_ROOT}/bin/xcrun" \
  "${TEMPORARY_ROOT}/bin/python3" \
  "${TEMPORARY_ROOT}/bin/swiftformat" \
  "${TEMPORARY_ROOT}/bin/swiftlint"

export PATH="${TEMPORARY_ROOT}/bin:${PATH}"
export TODOMATE_REAL_PYTHON3="${REAL_PYTHON3}"
export TODOMATE_DERIVED_DATA_DIR="${TEMPORARY_ROOT}/Derived Data"
export TODOMATE_RESULT_BUNDLE_DIR="${TEMPORARY_ROOT}/Test Results"
export TODOMATE_SCREENSHOT_OUTPUT_DIR="${TEMPORARY_ROOT}/Screenshot Output"

expect_failure() {
  local label="$1"
  local injected_failure="$2"
  local actual_status
  shift 2

  set +e
  TODOMATE_FAKE_FAILURE="${injected_failure}" just "$@" >/dev/null 2>&1
  actual_status=$?
  set -e

  if [[ "${actual_status}" -eq 0 ]]; then
    echo "error: ${label} swallowed an intentional ${injected_failure} failure" >&2
    exit 1
  fi

  if [[ "${actual_status}" -ne 42 ]]; then
    echo "error: ${label} replaced failure status 42 with ${actual_status}" >&2
    exit 1
  fi
}

expect_failure build xcodebuild build
expect_failure build-pipeline xcbeautify build
expect_failure test-domain swift test-domain
expect_failure test-data swift test-data
expect_failure test-app xcodebuild test-app
expect_failure test-app-runtime xcodebuild test-app-runtime
expect_failure screenshots-xcodebuild xcodebuild ui-screenshots
expect_failure test-app-no-result xcodebuild-no-bundle test-app
expect_failure test-app-runtime-no-result xcodebuild-no-bundle test-app-runtime
expect_failure screenshots-no-result xcodebuild-no-bundle ui-screenshots
expect_failure screenshots-export xcrun ui-screenshots
expect_failure screenshots-argument-generation python3-generate ui-screenshots
expect_failure screenshots-rename python3-rename ui-screenshots

expected_screenshot_derived_data="${TODOMATE_DERIVED_DATA_DIR}/ui-screenshots-signed"
readonly expected_screenshot_derived_data
expected_screenshot_result="${TODOMATE_RESULT_BUNDLE_DIR}/screenshots.xcresult"
readonly expected_screenshot_result
TODOMATE_FAKE_FAILURE="" \
TODOMATE_EXPECT_DERIVED_DATA_PATH="${expected_screenshot_derived_data}" \
TODOMATE_EXPECT_RESULT_BUNDLE_PATH="${expected_screenshot_result}" \
TODOMATE_EXPECT_TEST_ARGUMENT_ONE="-only-testing:TodoMateUITests/ScreenshotTests/testCapturePersonalBoard" \
TODOMATE_EXPECT_TEST_ARGUMENT_TWO="-only-testing:TodoMateUITests/ScreenshotTests/testCaptureMemo" \
TODOMATE_EXPECT_EXACT_SCREEN_ARGUMENTS=true \
TODOMATE_EXPECT_SCREENSHOT_MANIFEST="${TODOMATE_SCREENSHOT_OUTPUT_DIR}/manifest.json" \
TODOMATE_EXPECT_SCREENSHOT_OUTPUT_PATH="${TODOMATE_SCREENSHOT_OUTPUT_DIR}/" \
TODOMATE_EXPECT_SCREENSHOT_RENAME_PATH="${TODOMATE_SCREENSHOT_OUTPUT_DIR}" \
SCREENS="personal_board,memo" \
  just ui-screenshots >/dev/null 2>&1

expected_build_derived_data="${TODOMATE_DERIVED_DATA_DIR}/build-certificate-free"
readonly expected_build_derived_data
TODOMATE_FAKE_FAILURE="" \
TODOMATE_EXPECT_DERIVED_DATA_PATH="${expected_build_derived_data}" \
  just build >/dev/null 2>&1

expected_derived_data="${TODOMATE_DERIVED_DATA_DIR}/app-tests-signed"
readonly expected_derived_data
expected_result_bundle="${TODOMATE_RESULT_BUNDLE_DIR}/app.xcresult"
readonly expected_result_bundle

TODOMATE_FAKE_FAILURE="" \
TODOMATE_EXPECT_DERIVED_DATA_PATH="${expected_derived_data}" \
TODOMATE_EXPECT_RESULT_BUNDLE_PATH="${expected_result_bundle}" \
  just test-app >/dev/null 2>&1

expected_runtime_derived_data="${TODOMATE_DERIVED_DATA_DIR}/ui-runtime-signed"
readonly expected_runtime_derived_data
expected_runtime_result="${TODOMATE_RESULT_BUNDLE_DIR}/app-runtime.xcresult"
readonly expected_runtime_result
TODOMATE_FAKE_FAILURE="" \
TODOMATE_EXPECT_DERIVED_DATA_PATH="${expected_runtime_derived_data}" \
TODOMATE_EXPECT_RESULT_BUNDLE_PATH="${expected_runtime_result}" \
  just test-app-runtime >/dev/null 2>&1

if [[ ! -f "${expected_result_bundle}/Info.plist" || \
  ! -f "${expected_result_bundle}.todomate-complete" ]]; then
  echo "error: signed test path did not preserve its completed result marker" >&2
  exit 1
fi

expect_failure test-app-retry xcodebuild test-app

previous_result="${TODOMATE_RESULT_BUNDLE_DIR}/app.previous.xcresult"
readonly previous_result
if [[ ! -f "${previous_result}/Info.plist" || \
  ! -f "${previous_result}.todomate-complete" ]]; then
  echo "error: a failed retry did not preserve the prior completed result bundle" >&2
  exit 1
fi

rotation_result="${TEMPORARY_ROOT}/Rotation Results/app.xcresult"
readonly rotation_result
mkdir -p -- "${rotation_result}"
touch -- "${rotation_result}/Info.plist" "${rotation_result}.todomate-complete"
script/prepare_build_artifacts.bash prepare-result "${rotation_result}"
mkdir -p -- "${rotation_result}"
touch -- "${rotation_result}/partial-data"
if script/prepare_build_artifacts.bash finalize-result "${rotation_result}" >/dev/null 2>&1; then
  echo "error: result finalizer accepted a partial result bundle" >&2
  exit 1
fi
script/prepare_build_artifacts.bash prepare-result "${rotation_result}"
if [[ ! -f "${rotation_result%.xcresult}.previous.xcresult/Info.plist" || \
  ! -f "${rotation_result%.xcresult}.previous.xcresult.todomate-complete" ]]; then
  echo "error: a repeated partial retry replaced the prior completed result bundle" >&2
  exit 1
fi

if script/prepare_build_artifacts.bash validate-directory "/./todomate-root-probe" \
  >/dev/null 2>&1; then
  echo "error: artifact path validation accepted a root-adjacent '/.' path" >&2
  exit 1
fi

if TODOMATE_DERIVED_DATA_DIR="" TODOMATE_FAKE_FAILURE="" just build >/dev/null 2>&1; then
  echo "error: build accepted an empty DerivedData override" >&2
  exit 1
fi

if TODOMATE_RESULT_BUNDLE_DIR="" TODOMATE_FAKE_FAILURE="" just test-app >/dev/null 2>&1; then
  echo "error: test-app accepted an empty result-bundle override" >&2
  exit 1
fi

if TODOMATE_SCREENSHOT_OUTPUT_DIR="" TODOMATE_FAKE_FAILURE="" just ui-screenshots >/dev/null 2>&1; then
  echo "error: ui-screenshots accepted an empty output override" >&2
  exit 1
fi

unowned_output="${TEMPORARY_ROOT}/Unowned Screenshot Output"
readonly unowned_output
mkdir -p -- "${unowned_output}"
printf '%s\n' 'must survive' > "${unowned_output}/user-data.txt"
if TODOMATE_SCREENSHOT_OUTPUT_DIR="${unowned_output}" TODOMATE_FAKE_FAILURE="" \
  just ui-screenshots >/dev/null 2>&1; then
  echo "error: ui-screenshots accepted a non-empty unowned output directory" >&2
  exit 1
fi
if [[ ! -f "${unowned_output}/user-data.txt" ]]; then
  echo "error: ui-screenshots modified an unowned output directory" >&2
  exit 1
fi

symlink_marker_output="${TEMPORARY_ROOT}/Symlink Marker Output"
readonly symlink_marker_output
mkdir -p -- "${symlink_marker_output}"
printf '%s\n' 'outside marker target' > "${TEMPORARY_ROOT}/outside-marker"
ln -s -- "${TEMPORARY_ROOT}/outside-marker" \
  "${symlink_marker_output}/.todomate-managed-output"
if script/prepare_build_artifacts.bash prepare-managed-directory "${symlink_marker_output}" \
  >/dev/null 2>&1; then
  echo "error: managed screenshot output accepted a symbolic-link ownership marker" >&2
  exit 1
fi

trailing_symlink_target="${TEMPORARY_ROOT}/Trailing Symlink Target"
readonly trailing_symlink_target
trailing_symlink_path="${TEMPORARY_ROOT}/trailing-output-link"
readonly trailing_symlink_path
mkdir -p -- "${trailing_symlink_target}"
ln -s -- "${trailing_symlink_target}" "${trailing_symlink_path}"
if script/prepare_build_artifacts.bash prepare-managed-directory "${trailing_symlink_path}/" \
  >/dev/null 2>&1; then
  echo "error: managed screenshot output accepted a trailing-slash symbolic link" >&2
  exit 1
fi
if [[ -e "${trailing_symlink_target}/.todomate-managed-output" ]]; then
  echo "error: managed screenshot output modified a trailing-slash symlink target" >&2
  exit 1
fi

touch -- "${trailing_symlink_target}/.todomate-managed-output"
printf '%s\n' '[]' > "${trailing_symlink_target}/manifest.json"
printf '%s\n' 'must survive' > "${trailing_symlink_target}/user-data.txt"
if "${REAL_PYTHON3}" script/rename_screenshots.py "${trailing_symlink_path}/" \
  >/dev/null 2>&1; then
  echo "error: screenshot cleanup accepted a trailing-slash symbolic link" >&2
  exit 1
fi
if [[ ! -f "${trailing_symlink_target}/manifest.json" || \
  ! -f "${trailing_symlink_target}/user-data.txt" ]]; then
  echo "error: screenshot cleanup modified a trailing-slash symlink target" >&2
  exit 1
fi

unowned_rename_output="${TEMPORARY_ROOT}/Unowned Rename Output"
readonly unowned_rename_output
mkdir -p -- "${unowned_rename_output}"
printf '%s\n' '[]' > "${unowned_rename_output}/manifest.json"
printf '%s\n' 'must survive' > "${unowned_rename_output}/user-data.txt"
if "${REAL_PYTHON3}" script/rename_screenshots.py "${unowned_rename_output}" \
  >/dev/null 2>&1; then
  echo "error: screenshot cleanup accepted an unowned output directory" >&2
  exit 1
fi
if [[ ! -f "${unowned_rename_output}/manifest.json" || \
  ! -f "${unowned_rename_output}/user-data.txt" ]]; then
  echo "error: screenshot cleanup modified an unowned output directory" >&2
  exit 1
fi

traversal_root="${TEMPORARY_ROOT}/Traversal Output"
readonly traversal_root
traversal_output="${traversal_root}/screens"
readonly traversal_output
mkdir -p -- "${traversal_output}"
touch -- "${traversal_output}/.todomate-managed-output"
printf '%s\n' 'attachment' > "${traversal_output}/inside.png"
printf '%s\n' 'original' > "${traversal_root}/victim.png"
printf '%s\n' \
  '[{"attachments":[{"exportedFileName":"inside.png","suggestedHumanReadableName":"../victim_0_12345678-1234-1234-1234-123456789012.png"}]}]' \
  > "${traversal_output}/manifest.json"
if "${REAL_PYTHON3}" script/rename_screenshots.py "${traversal_output}" \
  >/dev/null 2>&1; then
  echo "error: screenshot cleanup accepted a traversal in suggestedHumanReadableName" >&2
  exit 1
fi
if [[ "$(<"${traversal_root}/victim.png")" != "original" || \
  ! -f "${traversal_output}/inside.png" ]]; then
  echo "error: screenshot cleanup modified files after rejecting suggested-name traversal" >&2
  exit 1
fi

printf '%s\n' \
  '[{"attachments":[{"exportedFileName":"../victim.png","suggestedHumanReadableName":"safe_0_12345678-1234-1234-1234-123456789012.png"}]}]' \
  > "${traversal_output}/manifest.json"
if "${REAL_PYTHON3}" script/rename_screenshots.py "${traversal_output}" \
  >/dev/null 2>&1; then
  echo "error: screenshot cleanup accepted a traversal in exportedFileName" >&2
  exit 1
fi
if [[ "$(<"${traversal_root}/victim.png")" != "original" ]]; then
  echo "error: screenshot cleanup modified an external file after rejecting exported-name traversal" >&2
  exit 1
fi

QUALITY_FIXTURE="${TEMPORARY_ROOT}/quality fixture"
readonly QUALITY_FIXTURE
mkdir -p -- "${QUALITY_FIXTURE}/script"
cp -- "${REPOSITORY_ROOT}/script/run_swift_quality_checks.bash" "${QUALITY_FIXTURE}/script/"
touch -- "${QUALITY_FIXTURE}/.swiftformat" "${QUALITY_FIXTURE}/.swiftlint.yml"

git -C "${QUALITY_FIXTURE}" init -q
git -C "${QUALITY_FIXTURE}" config user.name "Contract Verifier"
git -C "${QUALITY_FIXTURE}" config user.email "contract-verifier@example.invalid"
printf '%s\n' 'struct Original {}' > "${QUALITY_FIXTURE}/원본.swift"
git -C "${QUALITY_FIXTURE}" add -- "원본.swift"
git -C "${QUALITY_FIXTURE}" -c commit.gpgsign=false commit -qm "fixture baseline"

if CI=true "${QUALITY_FIXTURE}/script/run_swift_quality_checks.bash" >/dev/null 2>&1; then
  echo "error: quality checks accepted CI without PRE_COMMIT_BASE" >&2
  exit 1
fi

if CI=TRUE "${QUALITY_FIXTURE}/script/run_swift_quality_checks.bash" >/dev/null 2>&1; then
  echo "error: quality checks accepted uppercase CI without PRE_COMMIT_BASE" >&2
  exit 1
fi

if PRE_COMMIT_BASE=missing-revision \
  "${QUALITY_FIXTURE}/script/run_swift_quality_checks.bash" >/dev/null 2>&1; then
  echo "error: quality checks accepted an unavailable PRE_COMMIT_BASE" >&2
  exit 1
fi

git -C "${QUALITY_FIXTURE}" mv -- "원본.swift" "한글 이름.swift"
printf '%s\n' 'struct NewFile {}' > "${QUALITY_FIXTURE}/새 파일.swift"

QUALITY_FILE_LIST="${TEMPORARY_ROOT}/quality-files.txt"
readonly QUALITY_FILE_LIST
(
  cd "${QUALITY_FIXTURE}"
  PRE_COMMIT_BASE=HEAD TODOMATE_FAKE_FILE_LIST="${QUALITY_FILE_LIST}" \
    script/run_swift_quality_checks.bash >/dev/null
)

renamed_file="${QUALITY_FIXTURE}/한글 이름.swift"
readonly renamed_file
untracked_file="${QUALITY_FIXTURE}/새 파일.swift"
readonly untracked_file
found_renamed=false
found_untracked=false
while IFS= read -r path; do
  if [[ "${path}" == "${renamed_file}" ]]; then found_renamed=true; fi
  if [[ "${path}" == "${untracked_file}" ]]; then found_untracked=true; fi
done < "${QUALITY_FILE_LIST}"

if [[ "${found_renamed}" != true || "${found_untracked}" != true ]]; then
  echo "error: quality checks missed a staged rename or untracked non-ASCII Swift path" >&2
  exit 1
fi

printf '%s\n' 'struct Partial { let value = 1 }' > "${QUALITY_FIXTURE}/Partial.swift"
git -C "${QUALITY_FIXTURE}" add -- "Partial.swift"
printf '%s\n' 'struct Partial { let value = 2 }' > "${QUALITY_FIXTURE}/Partial.swift"
if (
  cd "${QUALITY_FIXTURE}"
  PRE_COMMIT_BASE=HEAD script/run_swift_quality_checks.bash >/dev/null 2>&1
); then
  echo "error: quality checks accepted a partially staged Swift file" >&2
  exit 1
fi

printf '%s\n' 'struct Partial { let value = 1 }' > "${QUALITY_FIXTURE}/Partial.swift"
printf '%s\n' 'struct MissingFromWorktree {}' > "${QUALITY_FIXTURE}/MissingFromWorktree.swift"
git -C "${QUALITY_FIXTURE}" add -- "MissingFromWorktree.swift"
rm -f -- "${QUALITY_FIXTURE}/MissingFromWorktree.swift"
if (
  cd "${QUALITY_FIXTURE}"
  PRE_COMMIT_BASE=HEAD script/run_swift_quality_checks.bash >/dev/null 2>&1
); then
  echo "error: quality checks accepted a staged Swift file absent from the working tree" >&2
  exit 1
fi

RANGE_FIXTURE="${TEMPORARY_ROOT}/committed range fixture"
readonly RANGE_FIXTURE
mkdir -p -- "${RANGE_FIXTURE}/script"
cp -- "${REPOSITORY_ROOT}/script/run_swift_quality_checks.bash" "${RANGE_FIXTURE}/script/"
touch -- "${RANGE_FIXTURE}/.swiftformat" "${RANGE_FIXTURE}/.swiftlint.yml"
git -C "${RANGE_FIXTURE}" init -q
git -C "${RANGE_FIXTURE}" config user.name "Contract Verifier"
git -C "${RANGE_FIXTURE}" config user.email "contract-verifier@example.invalid"
printf '%s\n' 'struct RangeFixture {}' > "${RANGE_FIXTURE}/RangeFixture.swift"
git -C "${RANGE_FIXTURE}" add -- "RangeFixture.swift"
git -C "${RANGE_FIXTURE}" -c commit.gpgsign=false commit -qm "range baseline"
printf '%s\n' 'struct RangeFixture { let value = 1 }' > "${RANGE_FIXTURE}/RangeFixture.swift"
git -C "${RANGE_FIXTURE}" add -- "RangeFixture.swift"
git -C "${RANGE_FIXTURE}" -c commit.gpgsign=false commit -qm "range change"
printf '%s\n' 'struct RangeFixture { let value = 2 }' > "${RANGE_FIXTURE}/RangeFixture.swift"
if (
  cd "${RANGE_FIXTURE}"
  PRE_COMMIT_BASE=HEAD^ script/run_swift_quality_checks.bash >/dev/null 2>&1
); then
  echo "error: committed-range quality checks accepted uncommitted Swift contents" >&2
  exit 1
fi
printf '%s\n' 'struct RangeFixture { let value = 1 }' > "${RANGE_FIXTURE}/RangeFixture.swift"
rm -f -- "${RANGE_FIXTURE}/RangeFixture.swift"
if (
  cd "${RANGE_FIXTURE}"
  PRE_COMMIT_BASE=HEAD^ script/run_swift_quality_checks.bash >/dev/null 2>&1
); then
  echo "error: committed-range quality checks accepted a selected Swift file absent from the working tree" >&2
  exit 1
fi

if [[ -d .test-logs && "${INITIAL_TEST_LOGS_PRESENT}" != true ]]; then
  echo "error: a canonical recipe created .test-logs" >&2
  exit 1
fi

FINAL_RAW_LOG_LIST="${TEMPORARY_ROOT}/final-raw-log-paths"
readonly FINAL_RAW_LOG_LIST
find . -type d \( -name .git -o -name .build \) -prune -o \
  -type f -name '*.log' -print0 > "${FINAL_RAW_LOG_LIST}"

while IFS= read -r -d '' path; do
  if ! nul_list_contains "${path}" "${INITIAL_RAW_LOG_LIST}"; then
    echo "error: canonical recipes created a repo-local raw log: ${path}" >&2
    exit 1
  fi
done < "${FINAL_RAW_LOG_LIST}"

while IFS= read -r -d '' path; do
  if [[ ! -f "${path}" ]]; then
    echo "error: canonical recipes removed a pre-existing repo-local raw log: ${path}" >&2
    exit 1
  fi
done < "${INITIAL_RAW_LOG_LIST}"

FINAL_UNTRACKED_LIST="${TEMPORARY_ROOT}/final-untracked-paths"
readonly FINAL_UNTRACKED_LIST
git ls-files -z --others --exclude-standard > "${FINAL_UNTRACKED_LIST}"

while IFS= read -r -d '' path; do
  if ! nul_list_contains "${path}" "${INITIAL_UNTRACKED_LIST}"; then
    echo "error: canonical recipes created a non-ignored repository artifact: ${path}" >&2
    exit 1
  fi
done < "${FINAL_UNTRACKED_LIST}"

echo "just contract verified: topology, safe artifacts, changed-file discovery, and failure propagation"
