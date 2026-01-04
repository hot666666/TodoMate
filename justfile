# TodoMate SPM Build Commands

build: set -o pipefail && xcodebuild -scheme TodoMate -destination 'platform=macOS' -quiet 2>&1 | xcbeautify --quieter

test: set -o pipefail && xcodebuild test -scheme TodoMate -destination 'platform=macOS' 2>&1 | xcbeautify

# Run only a subset of tests related to your change.
# Usage examples:
# - just test-only TodoMateTests/InviteCodeGeneratorTests
# - just test-only TodoMateUITests/ScreenshotTests
test-only TEST_TARGET: set -o pipefail && xcodebuild test -scheme TodoMate -destination 'platform=macOS' -only-testing:"{{TEST_TARGET}}" 2>&1 | xcbeautify

# Run multiple targeted tests in one command.
# Usage:
# - just test-only-many TodoMateTests/InviteCodeGeneratorTests TodoMateTests/TodoMateTests
test-only-many *TEST_TARGETS: set -o pipefail && xcodebuild test -scheme TodoMate -destination 'platform=macOS' {{ for t in TEST_TARGETS { "-only-testing:\"" + t + "\"" } }} 2>&1 | xcbeautify
