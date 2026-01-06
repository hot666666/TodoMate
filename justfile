build:
    set -o pipefail && xcodebuild -scheme TodoMate -destination 'platform=macOS' -quiet 2>&1 | xcbeautify --quieter

test:
    set -o pipefail && xcodebuild test -scheme TodoMate -destination 'platform=macOS' 2>&1 | xcbeautify

# Firebase 에뮬레이터 없이 유닛 테스트만 실행
test-unit:
    set -o pipefail && xcodebuild test \
        -scheme TodoMate \
        -destination 'platform=macOS' \
        -skip-testing:TodoMateTests/Firebase \
        2>&1 | xcbeautify

# Firebase 에뮬레이터와 함께 Firebase 유닛 테스트만 실행
test-firebase: start-emulator
    set -o pipefail && xcodebuild test \
        -scheme TodoMate \
        -destination 'platform=macOS' \
        -only-testing:TodoMateTests/Firebase \
        SWIFT_ACTIVE_COMPILATION_CONDITIONS='$(inherited) USE_FIREBASE_EMULATOR' \
        2>&1 | xcbeautify; \
    just stop-emulator

# UI 테스트 (에뮬레이터 필요)
test-ui: start-emulator
    set -o pipefail && xcodebuild test \
        -scheme TodoMate \
        -destination 'platform=macOS' \
        -only-testing:TodoMateUITests \
        SWIFT_ACTIVE_COMPILATION_CONDITIONS='$(inherited) USE_FIREBASE_EMULATOR' \
        2>&1 | xcbeautify; \
    just stop-emulator

# 전체 테스트 (유닛 → Firebase → UI 순서)
test-all: test-unit test-firebase test-ui

# 에뮬레이터 시작
start-emulator:
    @echo "🔥 Starting Firebase emulator..."
    @cd FirebaseEmulator && firebase emulators:start --only firestore &
    @sleep 5
    @nc -z localhost 8080 && echo "✅ Emulator ready on port 8080"
    @echo ""
    @echo "🧪 Running tests..."
    @echo ""

# 에뮬레이터 중지
stop-emulator:
    @echo ""
    @-lsof -ti:8080 | xargs kill -9 2>/dev/null || true
    @-lsof -ti:4000 | xargs kill -9 2>/dev/null || true
    @echo "🛑 Emulator stopped"
