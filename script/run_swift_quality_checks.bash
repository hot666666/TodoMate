#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -z "${SCRIPT_DIR}" || ! -d "${SCRIPT_DIR}" ]]; then
  echo "error: failed to resolve the quality script directory" >&2
  exit 2
fi
readonly SCRIPT_DIR

REPOSITORY_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
if [[ -z "${REPOSITORY_ROOT}" || ! -e "${REPOSITORY_ROOT}/.git" ]]; then
  echo "error: failed to resolve the repository root" >&2
  exit 2
fi
readonly REPOSITORY_ROOT

CANDIDATE_LIST="$(mktemp)"
if [[ -z "${CANDIDATE_LIST}" || ! -f "${CANDIDATE_LIST}" ]]; then
  echo "error: failed to create a candidate file list" >&2
  exit 2
fi
readonly CANDIDATE_LIST

STAGED_LIST="$(mktemp)"
if [[ -z "${STAGED_LIST}" || ! -f "${STAGED_LIST}" ]]; then
  rm -f -- "${CANDIDATE_LIST}"
  echo "error: failed to create a staged file list" >&2
  exit 2
fi
readonly STAGED_LIST

BASE_RANGE_LIST="$(mktemp)"
if [[ -z "${BASE_RANGE_LIST}" || ! -f "${BASE_RANGE_LIST}" ]]; then
  rm -f -- "${CANDIDATE_LIST}" "${STAGED_LIST}"
  echo "error: failed to create a committed-range file list" >&2
  exit 2
fi
readonly BASE_RANGE_LIST

SWIFTFORMAT_FILE_LIST="$(mktemp)"
if [[ -z "${SWIFTFORMAT_FILE_LIST}" || ! -f "${SWIFTFORMAT_FILE_LIST}" ]]; then
  rm -f -- "${CANDIDATE_LIST}" "${STAGED_LIST}" "${BASE_RANGE_LIST}"
  echo "error: failed to create a SwiftFormat file list" >&2
  exit 2
fi
readonly SWIFTFORMAT_FILE_LIST

cleanup() {
  rm -f -- \
    "${CANDIDATE_LIST}" \
    "${STAGED_LIST}" \
    "${BASE_RANGE_LIST}" \
    "${SWIFTFORMAT_FILE_LIST}"
}
trap cleanup EXIT

cd "${REPOSITORY_ROOT}"

for tool in git swiftformat swiftlint; do
  if ! command -v "${tool}" >/dev/null 2>&1; then
    echo "error: required quality tool is unavailable: ${tool}" >&2
    exit 2
  fi
done

is_ci_value() {
  case "$1" in
    "" | 0 | [Ff][Aa][Ll][Ss][Ee] | [Nn][Oo] | [Oo][Ff][Ff]) return 1 ;;
    *) return 0 ;;
  esac
}

if [[ -z "${PRE_COMMIT_BASE:-}" ]]; then
  if is_ci_value "${CI:-}" || is_ci_value "${GITHUB_ACTIONS:-}"; then
    echo "error: PRE_COMMIT_BASE is required in CI; fetch the base history and set it explicitly" >&2
    exit 2
  fi
else
  if [[ "${PRE_COMMIT_BASE}" == -* ]]; then
    echo "error: PRE_COMMIT_BASE must be a revision, not an option: ${PRE_COMMIT_BASE}" >&2
    exit 2
  fi

  if ! git rev-parse --verify --quiet "${PRE_COMMIT_BASE}^{commit}" >/dev/null; then
    echo "error: PRE_COMMIT_BASE is unavailable: ${PRE_COMMIT_BASE}; fetch the base history first" >&2
    exit 2
  fi

  if ! git merge-base "${PRE_COMMIT_BASE}" HEAD >/dev/null; then
    echo "error: PRE_COMMIT_BASE has no merge base with HEAD: ${PRE_COMMIT_BASE}" >&2
    exit 2
  fi

  git diff -z --name-only --diff-filter=ACMR "${PRE_COMMIT_BASE}...HEAD" -- '*.swift' \
    > "${BASE_RANGE_LIST}"

  while IFS= read -r -d '' path; do
    if [[ ! -f "${path}" ]]; then
      echo "error: committed-range Swift file is absent from the working tree: ${path}" >&2
      exit 2
    fi

    if ! git diff --quiet HEAD -- "${path}"; then
      echo "error: committed-range Swift file has uncommitted changes: ${path}" >&2
      echo "error: verify the committed range from a clean working tree" >&2
      exit 2
    fi
  done < "${BASE_RANGE_LIST}"

  cat -- "${BASE_RANGE_LIST}" >> "${CANDIDATE_LIST}"
fi

git diff --cached -z --name-only --diff-filter=ACMR -- '*.swift' > "${STAGED_LIST}"

while IFS= read -r -d '' path; do
  if [[ ! -f "${path}" ]]; then
    echo "error: staged Swift file is absent from the working tree: ${path}" >&2
    echo "error: restore the staged file or unstage it before running quality checks" >&2
    exit 2
  fi

  if ! git diff --quiet -- "${path}"; then
    echo "error: staged Swift file also has unstaged changes: ${path}" >&2
    echo "error: stage the final file contents or unstage it before running quality checks" >&2
    exit 2
  fi
done < "${STAGED_LIST}"

cat -- "${STAGED_LIST}" >> "${CANDIDATE_LIST}"
git diff -z --name-only --diff-filter=ACMR -- '*.swift' >> "${CANDIDATE_LIST}"
git ls-files -z --others --exclude-standard -- '*.swift' >> "${CANDIDATE_LIST}"

declare -a swift_files=()

append_swift_file() {
  local path="$1"
  local absolute_path
  local existing

  if [[ "${path}" == *$'\n'* || "${path}" == *$'\r'* ]]; then
    echo "error: Swift file paths containing newlines are unsupported: ${path}" >&2
    exit 2
  fi

  if [[ -z "${path}" ]]; then
    return
  fi

  if [[ ! -f "${path}" ]]; then
    echo "error: selected Swift file is absent from the working tree: ${path}" >&2
    echo "error: restore the committed/staged file or verify again after its deletion is committed" >&2
    exit 2
  fi

  absolute_path="${REPOSITORY_ROOT}/${path}"
  if (( ${#swift_files[@]} > 0 )); then
    for existing in "${swift_files[@]}"; do
      if [[ "${existing}" == "${absolute_path}" ]]; then
        return
      fi
    done
  fi

  swift_files+=("${absolute_path}")
}

while IFS= read -r -d '' path; do
  append_swift_file "${path}"
done < "${CANDIDATE_LIST}"

if (( ${#swift_files[@]} == 0 )); then
  echo "No changed Swift files to lint. Set PRE_COMMIT_BASE=<commit> to check a committed range."
  exit 0
fi

for path in "${swift_files[@]}"; do
  printf '%s\n' "${path}" >> "${SWIFTFORMAT_FILE_LIST}"
done

echo "Linting ${#swift_files[@]} changed Swift file(s)."
swiftformat --lint --config .swiftformat --cache ignore --filelist "${SWIFTFORMAT_FILE_LIST}"
swiftlint lint \
  --strict \
  --force-exclude \
  --no-cache \
  --config .swiftlint.yml \
  "${swift_files[@]}"
