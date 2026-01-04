# Pull Request

## 🧾 요약 (Summary)

- UI 검증을 위한 자동화된 스크린샷 테스트 시스템을 구축했습니다.
- 주요 화면(Board, Calendar, Profile 등)에 대한 스크린샷을 체계적으로 캡처하고 `screenshots/` 디렉토리에 저장합니다.

## 🛠️ 변경 사항 (Changes)

- **Test Infrastructure**:
  - `ScreenType`: 캡처할 화면 종류 정의 (PersonalBoard, Calendar, Profile, AddTaskOverlay 등)
  - `ScreenNavigator`: `accessibilityIdentifier`를 사용한 견고한 화면 탐색 로직 구현
  - `ScreenshotTests`: `XCTContext.runActivity`를 사용하여 테스트 단계 구조화 및 첨부 파일 관리 개선
  - `ScreenshotCapture`: 스크린샷 저장 로직 (이름 지정 등)
- **UI**:
  - `SidebarView`, `MainContainer`, `SettingsView`, `BoardView` 등에 테스트용 `accessibilityIdentifier` 추가
- **Config**:
  - `justfile`: `test-ui-screenshots` 명령어 개선 (테스트 전 디렉토리 정리, 결과 추출)
  - `ResultBundle`: 테스트 결과에서 첨부 파일 추출 로직 개선

## 🎯 배경 / 목적 (Why)

- Issue #110
- UI 변경 사항을 시각적으로 쉽고 빠르게 검증하기 위함입니다.
- 매번 수동으로 화면을 캡처하는 비용을 줄이고, 일관된 환경에서 스크린샷을 생성하여 UI 회귀를 방지합니다.

## ✅ 검증 (Verification)

- [x] `just test-ui-screenshots` 실행 시 10개의 주요 화면 스크린샷이 성공적으로 생성됨을 확인했습니다.
- [x] 생성된 이미지가 `screenshots/` 디렉토리에 올바른 이름으로 저장됨을 확인했습니다.

## 🖼️ 스크린샷 / 녹화 (UI 변경 시)

- **본 PR에 포함된 `screenshots/` 디렉토리 내의 파일들을 참고해주세요.**
- 포함된 스크린샷:
  - `window_default_0_0.png`
  - `personal_board_0_0.png`
  - `personal_calendar_0_0.png`
  - `add_task_overlay_0_0.png`
  - `profile_0_0.png`
  - 기타 주요 화면들

## ⚠️ 리스크 / 롤백 플랜 (Risks / Rollback)

- 없음 (테스트 코드 및 설정 추가)

## 📋 체크리스트 (Checklist)

- [x] 무관한 변경 없음
- [x] 필요 시 테스트 추가/수정
- [x] 필요 시 문서 업데이트

## 🔗 관련 링크 (Related)

- Fixes #110
