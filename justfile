# 테스트 로그 디렉토리
LOG_DIR := ".test-logs"
DERIVED_DATA_DIR := ".build/DerivedData"

build:
    @mkdir -p {{LOG_DIR}}
    set -o pipefail && xcodebuild \
        -project TodoMate.xcodeproj \
        -scheme TodoMate \
        -configuration Debug \
        -destination 'generic/platform=macOS' \
        -derivedDataPath {{DERIVED_DATA_DIR}}/build-unsigned \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        -quiet 2>&1 \
        | tee {{LOG_DIR}}/build.log \
        | xcbeautify --quieter \
        || { echo "❌ Build failed. See {{LOG_DIR}}/build.log"; exit 1; }

# 커밋 전 품질 검사 전체 실행 (자동 수정이 포함될 수 있음)
pre-commit:
    pre-commit run --all-files --show-diff-on-failure

# =============================================================================
# Domain Tests (SPM)
# =============================================================================
test-domain:
    @mkdir -p {{LOG_DIR}}
    @echo "🧪 Running TodoMateDomain tests..."
    set -o pipefail && cd TodoMateDomain && swift test 2>&1 \
        | tee ../{{LOG_DIR}}/domain.log \
        | xcbeautify \
        || { echo "❌ Test failed. See {{LOG_DIR}}/domain.log"; exit 1; }

# =============================================================================
# Data Tests (SPM)
# =============================================================================
# Data unit tests (GRDB 등)
test-data:
    @mkdir -p {{LOG_DIR}}
    @echo "🧪 Running TodoMateData unit tests..."
    set -o pipefail && cd TodoMateData && swift test --filter TodoMateDataTests 2>&1 \
        | tee ../{{LOG_DIR}}/data.log \
        | xcbeautify \
        || { echo "❌ Test failed. See {{LOG_DIR}}/data.log"; exit 1; }

# =============================================================================
# App Tests (xcodebuild)
# =============================================================================
# App unit tests (Store, Service 등)
test-app:
    @mkdir -p {{LOG_DIR}}
    @echo "🧪 Running TodoMate app unit tests..."
    set -o pipefail && xcodebuild test \
        -project TodoMate.xcodeproj \
        -scheme TodoMate \
        -configuration Debug \
        -destination 'platform=macOS' \
        -derivedDataPath {{DERIVED_DATA_DIR}}/app-tests \
        -only-testing:TodoMateTests \
        2>&1 \
        | tee {{LOG_DIR}}/app.log \
        | xcbeautify \
        || { echo "❌ Test failed. See {{LOG_DIR}}/app.log"; exit 1; }

# App runtime tests (빌드 후 런타임 문제 검증, 스크린샷 제외)
test-app-runtime:
    @mkdir -p {{LOG_DIR}}
    @echo "🧪 Running TodoMate runtime tests..."
    set -o pipefail && xcodebuild test \
        -project TodoMate.xcodeproj \
        -scheme TodoMate \
        -configuration Debug \
        -destination 'platform=macOS' \
        -derivedDataPath {{DERIVED_DATA_DIR}}/ui-runtime-signed \
        -only-testing:TodoMateUITests \
        -skip-testing:TodoMateUITests/ScreenshotTests \
        2>&1 \
        | tee {{LOG_DIR}}/app-runtime.log \
        | xcbeautify \
        || { echo "❌ Test failed. See {{LOG_DIR}}/app-runtime.log"; exit 1; }

# =============================================================================
# Combined Tests
# =============================================================================
# 전체 테스트 (Domain → Data → App 순서)
test-all: test-domain test-data test-app test-app-runtime

# 로그 정리
clean-logs:
    @rm -rf {{LOG_DIR}}
    @echo "🧹 Test logs cleaned"

# =============================================================================
# Screenshots
# =============================================================================
# UI 스크린샷 캡처 (특정 화면만 캡처하려면: SCREENSHOT_SCREENS=personal_board,memo just ui-screenshots)
ui-screenshots SCREENS="":
    @mkdir -p screenshots
    @rm -rf screenshots.xcresult
    @echo "Testing screens: {{ if SCREENS == "" { "ALL" } else { SCREENS } }}"
    set -o pipefail && xcodebuild test \
        -project TodoMate.xcodeproj \
        -scheme TodoMate \
        -configuration Debug \
        -destination 'platform=macOS' \
        -derivedDataPath {{DERIVED_DATA_DIR}}/ui-screenshots-signed \
        $(python3 script/generate_screenshot_test_args.py "{{SCREENS}}") \
        -resultBundlePath ./screenshots.xcresult \
        2>&1 | xcbeautify
    @xcrun xcresulttool export attachments \
        --path ./screenshots.xcresult \
        --manifest ./screenshots/manifest.json \
        --output-path ./screenshots/
    @python3 script/rename_screenshots.py ./screenshots
    @echo "📸 Screenshots saved to ./screenshots/"
