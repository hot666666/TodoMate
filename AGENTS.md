# TodoMate 에이전트 가이드

## 프로젝트 개요

TodoMate는 SwiftUI와 Clean Architecture로 만든 macOS 할 일 앱입니다. 개인 할 일은
GRDB에 저장하며, 그룹 피드·채팅 등 협업 인터페이스는 현재 mock 구현을 사용합니다.

- 지원 플랫폼: macOS 26 이상
- 언어·동시성: Swift 6.2 이상, strict concurrency
- 상태 관리: `@Observable` 기반 Store

## 작업 전 확인

1. `git status --short`로 기존 변경을 확인합니다.
2. 요청과 관련된 코드·테스트·문서를 먼저 탐색합니다.
3. 사용자가 만든 무관한 변경은 수정·스테이징·삭제하지 않습니다.
4. 새 의존성, 외부 서비스 변경, 데이터 마이그레이션은 필요한 경우 먼저 범위와
   검증 방법을 명확히 합니다.

## 모듈 경계

| 모듈              | 책임                                                      |
| ----------------- | --------------------------------------------------------- |
| `TodoMate/`       | 앱 진입점, DI, SwiftUI 화면, Store                        |
| `TodoMateDomain/` | 순수 Swift 도메인 모델과 유스케이스. 프레임워크 의존 금지 |
| `TodoMateData/`   | GRDB 저장소 구현과 외부 연동                              |
| `Common/`         | 여러 모듈에서 공유하는 유틸리티                           |

새 기능은 다음 경로를 기본으로 따릅니다.

1. 도메인 모델: `TodoMateDomain/Sources/TodoMateDomain/Entity/`
2. Repository 프로토콜: `TodoMateDomain/Sources/TodoMateDomain/Protocol/`
3. 유스케이스: `TodoMateDomain/Sources/TodoMateDomain/UseCase/`
4. 구현체: `TodoMateData/Sources/TodoMateData/`
5. 의존성 등록: `TodoMate/Application/Dependency/`
6. 화면·Store: `TodoMate/Features/`, `TodoMate/Models/`

뷰에서는 `@Environment(DIContainer.self)`로 등록된 의존성을 사용합니다. Domain의
타입이나 Repository 프로토콜에 GRDB·SwiftUI 의존성을 추가하지 않습니다.

## 명령어와 검증

모든 표준 검증은 `justfile`의 명령을 우선 사용합니다. 로그는 `.test-logs/`에
생성되며 커밋하지 않습니다.

| 변경 범위                               | 실행할 검증                                                                  |
| --------------------------------------- | ---------------------------------------------------------------------------- |
| Swift 소스, Xcode 프로젝트, 패키지 설정 | `just build`                                                                 |
| Domain 로직                             | `just test-domain`                                                           |
| Data 로직                               | `just test-data`                                                             |
| 앱 Store·서비스                         | `just test-app`                                                              |
| 런타임/UI 동작                          | `just test-app-runtime`                                                      |
| 포맷·린트                               | `just pre-commit`                                                            |
| 스크린샷                                | `just ui-screenshots` 또는 `SCREENS=personal_board,memo just ui-screenshots` |

`just pre-commit`은 포맷과 린트를 자동 수정할 수 있습니다. 실행 뒤에는 수정된 파일을
검토하고 필요한 파일만 명시적으로 스테이징합니다. 문서 또는 GitHub 템플릿만 바꿨다면
해당 파일의 문법 검사와 `git diff --check`로 충분하며 앱 빌드는 요구하지 않습니다.

## 구현 규칙

- `@Observable` 클래스는 `@MainActor`로 격리합니다.
- 비동기 작업은 `async`/`await`와 구조적 동시성을 사용하며 GCD를 새로 도입하지 않습니다.
- 화면은 상태 표현에 집중하고, 비즈니스 로직은 Store·유스케이스·서비스에 둡니다.
- UIKit은 별도 요청이 없으면 사용하지 않습니다.
- 새 핵심 로직에는 단위 테스트를 추가합니다. UI 테스트는 단위 테스트로 검증할 수 없는
  사용자 흐름에 한정합니다.
- 민감한 키·토큰·개인 정보와 테스트 로그를 저장소에 추가하지 않습니다.

## Skills

이 저장소는 다음 범주의 작업 Skill을 제공합니다.

- Swift·공개 API·동시성 설계
- SwiftUI 화면, 재사용 컴포넌트, Liquid Glass, 뷰 리팩터링
- Swift를 이용한 로깅과 POM 기반 XCUITest
- 요구사항 명세화, 설계 검증, 작업 인계

작업과 직접 일치하는 Skill이 있으면 적용합니다. Skill은 이 문서의 모듈 경계·검증·변경
범위 규칙을 보완하며 대체하지 않습니다.

## 참고 문서

| 주제                       | 위치                               |
| -------------------------- | ---------------------------------- |
| 앱 구조                    | `docs/app-architecture.md`         |
| Swift Testing              | `docs/swift-testing-guide.md`      |
| XCTest(UI)                 | `docs/xctest-ui-test.md`           |
| SwiftUI Toolbar API(macOS) | `docs/macos-26-toolbar-guide.md`   |
| 키보드 단축키              | `docs/macos-keyboard-shortcuts.md` |
| Nostr 마이그레이션 계획    | `docs/nostr/README.md`             |
| Slopad 에디터 계획         | `docs/slopad-editor/README.md`     |
| 반복 실패 런북             | `docs/agent-known-failures.md`     |

## 반복 실패 기록

같은 원인으로 두 번 이상 재발했거나, 환경·도구·검증 절차를 모르면 재현에 시간이 많이
드는 실패는 `docs/agent-known-failures.md`에 추가합니다. 일회성 구현 버그, 개인 환경
문제, 원시 테스트 로그는 기록하지 않습니다.

기록에는 증상, 재현 조건, 확인된 원인, 해결 또는 우회 방법, 검증 명령, 관련 이슈·PR,
그리고 더 이상 유효하지 않을 때 제거할 조건을 포함합니다.
