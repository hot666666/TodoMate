set shell := ["bash", "-euc"]

# Certificate/provisioning-free compile gate for the app and embedded Widget.
build:
    derived_data_root="${TODOMATE_DERIVED_DATA_DIR-.build/DerivedData}"; \
    derived_data_path="${derived_data_root}/build-certificate-free"; \
    script/prepare_build_artifacts.bash prepare-directory "${derived_data_path}"; \
    set -o pipefail; \
    xcodebuild \
        -project TodoMate.xcodeproj \
        -scheme TodoMate \
        -configuration Debug \
        -destination 'generic/platform=macOS' \
        -derivedDataPath "${derived_data_path}" \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        -quiet 2>&1 \
        | xcbeautify --quieter

# Lint changed Swift files without mutating them. In CI, set PRE_COMMIT_BASE.
pre-commit:
    @script/run_swift_quality_checks.bash
    @just verify-just-contract

# Validate recipe names, artifact paths, and pipeline failure propagation.
verify-just-contract:
    @script/verify_just_contract.bash

# =============================================================================
# Domain and Data Tests (SPM)
# =============================================================================
test-domain:
    @echo "🧪 Running TodoMateDomain tests..."
    set -o pipefail; cd TodoMateDomain; swift test 2>&1 \
        | xcbeautify

test-data:
    @echo "🧪 Running TodoMateData unit tests..."
    set -o pipefail; cd TodoMateData; swift test --filter TodoMateDataTests 2>&1 \
        | xcbeautify

# =============================================================================
# Signed App Tests (local runnable macOS environment required)
# =============================================================================
test-app:
    derived_data_root="${TODOMATE_DERIVED_DATA_DIR-.build/DerivedData}"; \
    result_bundle_root="${TODOMATE_RESULT_BUNDLE_DIR-.build/TestResults}"; \
    derived_data_path="${derived_data_root}/app-tests-signed"; \
    result_bundle_path="${result_bundle_root}/app.xcresult"; \
    script/prepare_build_artifacts.bash prepare-directory "${derived_data_path}"; \
    script/prepare_build_artifacts.bash prepare-result "${result_bundle_path}"; \
    echo "🧪 Running signed TodoMate app unit tests..."; \
    echo "Result bundle: ${result_bundle_path}"; \
    status=0; set -o pipefail; xcodebuild test \
        -project TodoMate.xcodeproj \
        -scheme TodoMate \
        -configuration Debug \
        -destination 'platform=macOS' \
        -derivedDataPath "${derived_data_path}" \
        -resultBundlePath "${result_bundle_path}" \
        -only-testing:TodoMateTests \
        2>&1 | xcbeautify || status=$?; \
    finalize_status=0; \
    script/prepare_build_artifacts.bash finalize-result "${result_bundle_path}" || finalize_status=$?; \
    if [[ "${status}" -ne 0 ]]; then exit "${status}"; fi; \
    exit "${finalize_status}"

test-app-runtime:
    derived_data_root="${TODOMATE_DERIVED_DATA_DIR-.build/DerivedData}"; \
    result_bundle_root="${TODOMATE_RESULT_BUNDLE_DIR-.build/TestResults}"; \
    derived_data_path="${derived_data_root}/ui-runtime-signed"; \
    result_bundle_path="${result_bundle_root}/app-runtime.xcresult"; \
    script/prepare_build_artifacts.bash prepare-directory "${derived_data_path}"; \
    script/prepare_build_artifacts.bash prepare-result "${result_bundle_path}"; \
    echo "🧪 Running signed TodoMate UI runtime tests..."; \
    echo "Requires macOS automation permission."; \
    echo "Result bundle: ${result_bundle_path}"; \
    status=0; set -o pipefail; xcodebuild test \
        -project TodoMate.xcodeproj \
        -scheme TodoMate \
        -configuration Debug \
        -destination 'platform=macOS' \
        -derivedDataPath "${derived_data_path}" \
        -resultBundlePath "${result_bundle_path}" \
        -only-testing:TodoMateUITests \
        -skip-testing:TodoMateUITests/ScreenshotTests \
        2>&1 | xcbeautify || status=$?; \
    finalize_status=0; \
    script/prepare_build_artifacts.bash finalize-result "${result_bundle_path}" || finalize_status=$?; \
    if [[ "${status}" -ne 0 ]]; then exit "${status}"; fi; \
    exit "${finalize_status}"

# Certificate/provisioning-free PR gate. Signed runnable tests are intentionally separate.
test-pr: pre-commit build test-domain test-data

# Full local validation. Requires signing and UI automation permissions.
test-all: test-pr test-app test-app-runtime

# =============================================================================
# Screenshots (signed deterministic fixture lane)
# =============================================================================
ui-screenshots:
    @screens="${SCREENS-}"; if [[ -z "${screens}" ]]; then echo "Testing screens: ALL"; else echo "Testing screens: ${screens}"; fi
    derived_data_root="${TODOMATE_DERIVED_DATA_DIR-.build/DerivedData}"; \
    result_bundle_root="${TODOMATE_RESULT_BUNDLE_DIR-.build/TestResults}"; \
    screenshot_output="${TODOMATE_SCREENSHOT_OUTPUT_DIR-screenshots}"; \
    screens="${SCREENS-}"; \
    derived_data_path="${derived_data_root}/ui-screenshots-signed"; \
    result_bundle_path="${result_bundle_root}/screenshots.xcresult"; \
    screenshot_args_text="$(python3 script/generate_screenshot_test_args.py "${screens}")"; \
    IFS=' ' read -r -a screenshot_args <<< "${screenshot_args_text}"; \
    script/prepare_build_artifacts.bash prepare-directory "${derived_data_path}"; \
    script/prepare_build_artifacts.bash prepare-managed-directory "${screenshot_output}"; \
    script/prepare_build_artifacts.bash prepare-result "${result_bundle_path}"; \
    status=0; set -o pipefail; xcodebuild test \
        -project TodoMate.xcodeproj \
        -scheme TodoMate \
        -configuration Debug \
        -destination 'platform=macOS' \
        -derivedDataPath "${derived_data_path}" \
        "${screenshot_args[@]}" \
        -resultBundlePath "${result_bundle_path}" \
        2>&1 | xcbeautify || status=$?; \
    finalize_status=0; \
    script/prepare_build_artifacts.bash finalize-result "${result_bundle_path}" || finalize_status=$?; \
    if [[ "${status}" -ne 0 ]]; then exit "${status}"; fi; \
    exit "${finalize_status}"
    @result_bundle_root="${TODOMATE_RESULT_BUNDLE_DIR-.build/TestResults}"; \
    screenshot_output="${TODOMATE_SCREENSHOT_OUTPUT_DIR-screenshots}"; \
    xcrun xcresulttool export attachments \
        --path "${result_bundle_root}/screenshots.xcresult" \
        --manifest "${screenshot_output}/manifest.json" \
        --output-path "${screenshot_output}/"
    @screenshot_output="${TODOMATE_SCREENSHOT_OUTPUT_DIR-screenshots}"; \
    python3 script/rename_screenshots.py "${screenshot_output}"
    @screenshot_output="${TODOMATE_SCREENSHOT_OUTPUT_DIR-screenshots}"; \
    echo "📸 Screenshots saved to ${screenshot_output}/"
