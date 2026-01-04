build:
    set -o pipefail && xcodebuild -scheme TodoMate -destination 'platform=macOS' -quiet 2>&1 | xcbeautify --quieter

test:
    set -o pipefail && xcodebuild test -scheme TodoMate -destination 'platform=macOS' 2>&1 | xcbeautify

# Run only a subset of tests related to your change.
# Usage examples:
# - just test-only TodoMateTests/InviteCodeGeneratorTests
# - just test-only TodoMateUITests/ScreenshotTests
test-only TEST_TARGET:
    set -o pipefail && xcodebuild test -scheme TodoMate -destination 'platform=macOS' -only-testing:"{{TEST_TARGET}}" 2>&1 | xcbeautify

# Run multiple targeted tests in one command.
# Usage:
# - just test-only-many TodoMateTests/InviteCodeGeneratorTests TodoMateTests/TodoMateTests
test-only-many +TEST_TARGETS:
    #!/usr/bin/env bash
    set -o pipefail
    args=""
    for t in {{TEST_TARGETS}}; do
        args="$args -only-testing:$t"
    done
    xcodebuild test -scheme TodoMate -destination 'platform=macOS' $args 2>&1 | xcbeautify

# Run UI screenshot tests and export screenshots to screenshots/
# Usage: just test-ui-screenshots
test-ui-screenshots:
    #!/usr/bin/env bash
    set -o pipefail
    RESULT_PATH="$(pwd)/TestResults.xcresult"
    rm -rf "$RESULT_PATH" screenshots/* 2>/dev/null || true
    mkdir -p screenshots
    xcodebuild test -scheme TodoMate -destination 'platform=macOS' \
        -only-testing:TodoMateUITests/ScreenshotTests \
        -resultBundlePath "$RESULT_PATH" 2>&1 | xcbeautify
    just export-screenshots "$RESULT_PATH"

# Export screenshots from xcresult to screenshots/
# Usage: just export-screenshots <path-to-xcresult>
export-screenshots RESULT_PATH:
    #!/usr/bin/env bash
    set -e
    mkdir -p screenshots
    echo "[*] Extracting screenshots from xcresult..."
    xcrun xcresulttool export attachments --path "{{RESULT_PATH}}" --output-path ./screenshots
    echo ""
    echo "[*] Renaming screenshots to human-readable names..."
    python3 script/rename_screenshots.py ./screenshots
    echo ""
    echo "[OK] Screenshots exported to screenshots/"
    ls -la screenshots/*.png 2>/dev/null | head -20
