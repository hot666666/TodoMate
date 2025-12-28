# TodoMate SPM Build Commands

build:
    set -o pipefail && xcodebuild -scheme TodoMate -destination 'platform=macOS' -quiet 2>&1 | xcbeautify --quieter

test:
    set -o pipefail && xcodebuild test -scheme TodoMate -destination 'platform=macOS' 2>&1 | xcbeautify
