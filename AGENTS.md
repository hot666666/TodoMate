# TodoMate 에이전트 가이드

## 프로젝트 개요

TodoMate는 SwiftUI와 Clean Architecture로 만든 macOS 할 일 앱입니다. 개인 할 일은
GRDB에 저장하며, 그룹 피드·채팅 등 협업 인터페이스는 현재 mock 구현을 사용합니다.

- 지원 플랫폼: macOS 26 이상
- 언어·동시성: Swift 6.2 이상, strict concurrency
- 현재 상태 관리: `@Observable` 기반 Store
- 목표 상태 관리: Presentation 계층의 TCA 기반 State·Action·Reducer
- 장기 제품 모델: Todo·Memo·Chat이 모두 속하는 Project 중심 local-first workspace

## 작업 전 확인

1. `git status --short`로 기존 변경을 확인합니다.
2. 요청과 관련된 코드·테스트·문서를 먼저 탐색합니다.
3. 사용자가 만든 무관한 변경은 수정·스테이징·삭제하지 않습니다.
4. 새 의존성, 외부 서비스 변경, 데이터 마이그레이션은 필요한 경우 먼저 범위와
   검증 방법을 명확히 합니다.

## 기준 브랜치와 Git 작업흐름

- 모든 독립 작업의 통합 기준 브랜치와 PR base는 `dev`입니다. `main`은 릴리스 통합
  브랜치로 취급하며, 별도 요청 없이 직접 작업하지 않습니다.
- 현재 `core-redesign`에는 `dev`에서 시작했지만 아직 `dev`에 반영되지 않은 Firebase
  제거와 GRDB 전환 작업이 있습니다. 이 변경에 의존하는 후속 작업은 Linear에 선행
  이슈를 연결하고 `core-redesign` 또는 그 후속 브랜치에서 명시적인 stacked 작업으로
  진행합니다.
- 독립 이슈는 최신 `dev`에서 `codex/HOT6-N-short-slug` 브랜치를 만듭니다. 선행 PR이
  병합되면 후속 브랜치를 `dev` 기준으로 다시 정렬하고 검증합니다.
- 작업 시작 전에 현재 브랜치, upstream, `dev`와의 공통 조상, dirty worktree를
  확인합니다. 사용자의 기존 변경이 있으면 별도 worktree를 사용하거나 중단하고
  충돌 범위를 알립니다.
- `dev`와 `main`에는 직접 커밋하지 않습니다. 승인된 Linear 작업 범위에서는 브랜치
  생성, 필요한 파일만 커밋, push, Draft PR 생성과 검증된 PR 병합까지 자율적으로
  수행할 수 있습니다.
- 승인된 Goal 범위의 PR은 exact remote HEAD 독립 리뷰, 지적 수정 후 재리뷰, 설정된
  required check의 성공, unresolved review thread 0건과 mergeability 확인을 모두 통과한
  뒤 병합합니다. required check가 0건이면 그 사실을 evidence에 명시합니다.
- stacked PR은 선행 PR부터 병합하고 후속 브랜치를 최신 `dev`에 재정렬한 뒤 같은 검증과
  리뷰 gate를 다시 통과시킵니다. 충돌이 제품 결정·호환성·데이터 정책을 요구할 때만
  사용자에게 판단을 요청합니다.
- 릴리스, 태그, 공증과 배포는 별도 승인 없이는 수행하지 않습니다.
- PR 제목·본문·진행 comment·review 요약은 한글로 작성합니다. PR 본문은 실제 diff와
  검증 결과만 사용해 `목적 / 주요 변경사항 / 검증 / 제한사항·후속` 순서로 간결하게
  유지합니다.

## Linear 실행 계약

설계의 canonical working source는
[TodoMate Future Core Architecture v0.2](https://linear.app/hot6/document/todomate-future-core-architecture-v02-05b1682c21b0)입니다.
제품·package·화면 경계가 바뀌면 개별 이슈보다 이 문서와 관련 Linear Project 설명을
먼저 갱신합니다.

### 이슈 필수 형식

실행 가능한 이슈는 다음 내용을 포함해야 합니다.

1. **목적**: 구현 활동이 아니라 달성할 결과
2. **범위**: 이 이슈가 소유하는 변경
3. **제외 범위**: 후속 이슈나 다른 Project가 소유하는 내용
4. **Acceptance Criteria**: 체크 가능한 완료 조건
5. **선행 이슈**: Linear blocker 관계와 설명
6. **검증 명령**: 완료를 증명할 정확한 명령과 필요한 수동 검증
7. **참고 문서**: canonical architecture 및 관련 저장소 문서

이슈 관계는 설명의 텍스트만으로 표현하지 않고 Linear의 `blocked by` / `blocks`
관계에도 동일하게 반영합니다.

### 상태와 선택 규칙

- `Backlog`: 설계 또는 선행 작업이 남았거나 아직 실행 순서에 들어오지 않은 이슈
- `Todo`: 요구사항과 검증 방법이 명확하고 모든 blocker가 해결된 Ready 이슈
- `In Progress`: 현재 구현 중인 이슈. 같은 코드 경계의 신규 구현은 하나만 둡니다.
- `In Review`: 구현, 검증, 독립 리뷰, 수정과 Draft PR 생성까지 완료된 이슈
- `Done`: review/check/thread/mergeability gate를 통과한 PR이 `dev`에 반영되고, merge된
  exact SHA에서 최종 완료 조건을 다시 확인한 이슈

승인된 Project 또는 Milestone 목표가 실행 중이면 다음 순서로 계속 진행합니다.

1. Linear, canonical architecture, 현재 저장소 상태를 동기화합니다.
2. 현재 범위의 `In Progress` 이슈와 연결 브랜치가 있으면 먼저 복구해 완료 또는
   명시적 blocker 상태로 정리합니다.
3. 진행 중 이슈가 없으면 unblocked `Todo` 중 후속 작업을 가장 많이 해제하는 이슈를
   선택합니다.
4. 선택한 이슈를 `In Progress`로 옮기고 구현 범위와 검증 계획을 기록합니다.
5. 구현 → 관련 `just` 검증 → 독립 리뷰 → 수정 → 재검증을 수행합니다.
6. Linear에 브랜치, 커밋, 검증 명령과 결과, 제한사항, PR을 기록합니다.
7. `In Review`에서 exact remote HEAD 기준 독립 리뷰, 지적 수정과 재리뷰, required check,
   unresolved review thread 0건, mergeability를 확인하고 GitHub 또는 Linear에 최종 PASS
   evidence를 남깁니다.
8. gate가 통과하면 PR을 병합하고 merge된 exact SHA에서 필수 검증을 다시 실행한 뒤
   `Done`으로 옮깁니다. stacked 후속 브랜치는 최신 `dev`에 재정렬해 다시 검증합니다.
9. 한 이슈가 막히면 blocker와 선택지를 기록하고 다른 Ready 이슈를 진행합니다.

승인된 실행 목표 안에서는 다음 작업을 추가 승인 없이 수행할 수 있습니다.

- 다음 unblocked 이슈 선택과 Linear 상태·댓글·의존 관계 갱신
- 코드·테스트·문서 수정과 관련 `just` 검증
- 작업 브랜치 생성, 명시적 파일 커밋, push와 Draft PR 생성
- 리뷰 지적 수정, 재검증과 결과 기록
- review/check/thread/mergeability gate를 통과한 PR 병합과 stacked 후속 브랜치 재정렬

다음 경우에는 임의로 결정하지 않고 중단해 사용자 판단을 요청합니다.

- 제품 동작이나 canonical architecture를 바꾸는 미결정 사항
- 파괴적 데이터 마이그레이션 또는 호환성 손실
- 새 외부 의존성·서비스 도입
- 인증서, 비밀정보, 운영 계정 권한 사용
- 릴리스, 태그, 공증, 배포
- merge conflict 해결이 제품 동작·호환성·데이터 정책을 새로 결정해야 하는 경우
- 사용자 변경과의 충돌 또는 완료를 판정할 수 없는 검증 환경

## 현재 모듈 경계

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

## 목표 package 경계

목표 경계는 아직 모두 구현된 구조가 아닙니다. 해당 Linear 이슈가 시작되기 전에는
현재 경계를 임의로 대규모 이동하지 않습니다.

| Package                  | 책임                                                               |
| ------------------------ | ------------------------------------------------------------------ |
| `TodoMateCore`           | Domain, SyncContracts, Application typed client와 순수 정책        |
| `TodoMatePersistence`    | GRDB schema, migration, projection, outbox와 Widget read model     |
| `TodoMateSync`           | SyncEngine, Mock/Live Relay adapter, E2EE와 Apple KeyStore         |
| `TodoMatePresentation`   | TCA Feature, navigation, presentation과 TestStore fixture          |
| `TodoMate.app`           | Scene, Window, AppKit, Sparkle, AppIntent와 composition root       |

- GRDB가 Project·Todo·Memo·Chat·Membership의 canonical source입니다.
- TCA State에는 observation projection과 transient UI state만 둡니다.
- `RelayClient` 계약은 Mock과 Live가 공유하며, 실제 Relay 서버 없이도 동일한 client
  경로로 Todo·Memo·Chat·membership·E2EE를 검증합니다.
- Relay URL, Nostr 개인키, Project 평문 키를 Presentation State나 로그에 넣지 않습니다.

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

Linear 이슈의 `검증 명령`에는 위 명령 중 해당 범위를 정확히 적습니다. 새 package나
검증 계층 때문에 기존 recipe로 증명할 수 없다면 구현과 함께 canonical `just` recipe를
추가하고, 명령의 실제 성공 결과를 Linear에 기록합니다.

## 구현 규칙

- 기존 `@Observable` 클래스는 `@MainActor`로 격리합니다. TCA 전환 대상 Feature에는
  별도 `@Observable` Store를 새로 만들지 않습니다.
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
| Deferred RelayLive 연구    | `docs/nostr/README.md`             |
| Slopad 에디터 계획         | `docs/slopad-editor/README.md`     |
| 반복 실패 런북             | `docs/agent-known-failures.md`     |

## 반복 실패 기록

같은 원인으로 두 번 이상 재발했거나, 환경·도구·검증 절차를 모르면 재현에 시간이 많이
드는 실패는 `docs/agent-known-failures.md`에 추가합니다. 일회성 구현 버그, 개인 환경
문제, 원시 테스트 로그는 기록하지 않습니다.

기록에는 증상, 재현 조건, 확인된 원인, 해결 또는 우회 방법, 검증 명령, 관련 이슈·PR,
그리고 더 이상 유효하지 않을 때 제거할 조건을 포함합니다.
