# TodoMate

TodoMate는 사용자들이 그룹을 통해 오늘의 할 일들을 실시간으로 공유할 수 있습니다.

## 마이그레이션

| 버전 | 변경 사항 | 비고 |
| :--- | :--- | :--- |
| v1.1.0 | `Todo`, `Memo` 엔티티에 `isDeleted: Bool` 추가 | Soft Delete 지원 |

## 도구

| 항목 | 용도 | 비고 |
| :--- | :--- | :--- |
| Xcode 26(Swift 6.2) | 핵심 개발 환경 및 최신 스위프트 언어 기능 활용 | - |
| just(1.45.)  | 빌드, 테스트, 에뮬레이터 실행 등 복잡한 커맨드 단축 실행 | justfile |
| pre-commit(4.3.) | 커밋 전 코드 스타일 교정 및 컨벤션 체크 자동화 | swiftformat(0.58), swiftlint(0.61) |
| xcbeautify(2.30.) | 터미널 빌드/테스트 로그 가독성 향상 | - |
| Firebase CLI(15.1.) | 로컬 에뮬레이터(Firestore 등) 구동을 위한 필수 엔진 | openJDK(21), nodejs(24) |
