# TodoMate SPM 경계와 점진적 migration 계획

> 상태: 목표 compile-time 경계와 migration handoff. 이 문서는 package/target을 실제로
> 생성하거나 현재 파일 이동이 완료되었다고 주장하지 않는다.
>
> 기준 revision: `dev@f5721236f581f85a3bf6573dfe1161d7fb8d67e2`
>
> 제품·runtime canonical source:
> [TodoMate Future Core Architecture v0.2](https://linear.app/hot6/document/todomate-future-core-architecture-v02-05b1682c21b0)
>
> Repository handoff:
> [앱 아키텍처](app-architecture.md) ·
> [Command Palette migration 계약](command-palette-migration-contract.md)

이 계획은 canonical architecture의 네 package 경계를 바꾸지 않고, 현재
`Common` / `TodoMateDomain` / `TodoMateData` / app target에서 그 경계로 이동할 때의
consumer API, import 방향, 파일 owner와 순서를 구체화한다. 실제 public signature와 schema는
각 구현 이슈의 테스트와 review checkpoint에서 확정하되 이 문서의 dependency와 secret
ownership을 거슬러서는 안 된다.

## 소비 지점부터 고정

아래 코드는 구현 복사본이 아니라 목표 API를 평가하는 call-site contract다. 타입 이름의
세부 철자는 후속 이슈에서 다듬을 수 있지만 concrete adapter, raw key와 stringly ID가 이
사용 지점에 나타나지 않는다는 조건은 고정한다.

### TCA Feature → typed Application client

Presentation은 `TodoMateApplication`의 `Sendable` client value를 TCA dependency로 등록한다.
Application target 자체는 TCA를 import하지 않는다.

```swift
@Dependency(\.projectClient) var projects
@Dependency(\.todoClient) var todos
@Dependency(\.memoClient) var memos
@Dependency(\.chatClient) var chat

case let .view(.createTodo(title)):
  return .run { [projectID] send in
    let result: Result<TodoID, TodoClientError>
    do {
      result = .success(
        try await todos.create(
          CreateTodoCommand(projectID: projectID, title: title)
        )
      )
    } catch let error as TodoClientError {
      result = .failure(error)
    } catch {
      result = .failure(.unexpected)
    }
    await send(.internal(.todoCreated(result)))
  }

case .internal(.startObservation):
  return .run { [projectID] send in
    for try await snapshot in todos.observe(projectID: projectID) {
      await send(.internal(.todosObserved(snapshot)))
    }
  }
  .cancellable(id: CancelID.project(projectID), cancelInFlight: true)
```

- `ProjectID`, `TodoID`, `MemoID`, `ChatChannelID`와 command/result는 Domain/Application typed
  value다. Relay URL, raw `String` identity와 `useCache: Bool`을 노출하지 않는다.
- Project/Todo/Memo/Chat client는 GRDB commit 결과를 canonical entity로 Feature State에
  직접 삽입하지 않는다. observation이 같은 ID의 projection을 돌려줄 때 UI가 갱신된다.
- Project 전환이나 dismiss는 observation/effect를 ID 단위로 취소한다. 늦은 응답은 request
  identity를 확인한 뒤 무시한다.
- Feature는 `GRDBDatabase`, `SyncEngine`, `RelayMock`, Keychain 구현을 import하지 않는다.
- 위 예제의 네 client는 최종 surface를 한 번에 보여 준다. HOT6-9 최초 shell에는 HOT6-26이
  제공한 Project/Todo/Memo client만 존재하며 Chat client는 HOT6-36에서 추가한다.

### Application / SyncEngine → capability port와 RelayClient

Application client는 SyncContracts의 persistence/sync capability port에 local command를
보낸다. local projection과 outbox가 같은 transaction에서 commit된 뒤 SyncEngine이 outbox를
소비한다. Application은 Relay에 publish하지 않으며 SyncEngine만 `RelayClient`를 받는다.

```swift
let commit = try await projectStore.apply(
  .createTodo(command),
  authoredBy: authorID
)
await syncWakeup.requestFlush(projectID: commit.projectID)

let subscription = RelaySubscription(
  topic: .chat(projectID: projectID, channelID: channelID),
  after: cursor
)

for try await event in relay.events(for: subscription) {
  try await inbound.accept(event)
}

try await relay.publish(
  RelayPublishRequest(topic: .todos(projectID: projectID), envelope: sealedEnvelope)
)
```

- `RelayClient` protocol과 request/response/event/error/connection DTO는
  `TodoMateSyncContracts` 한 곳에서만 선언한다.
- `SyncEngine`, `RelayMock`과 후속 `RelayLive`는 그 선언을 구현하거나 소비하며 protocol을
  다시 선언하지 않는다.
- `RelayMock` event도 signature/key-epoch preflight → open → authorization → reconcile →
  GRDB commit의 production-shaped inbound path를 통과한다. GRDB에 직접 seed하지 않는다.
- Persistence와 Sync concrete target은 서로 import하지 않는다. Host가
  `SyncStore`/outbox capability 구현과 SyncEngine을 조립하므로 compile cycle이 생기지 않는다.

### Identity recovery → IdentityKeyStore

`IdentityKeyStore`는 private key bytes를 반환하는 CRUD repository가 아니라 Keychain 안의
identity로 작업하는 capability port다.

```swift
let identity = try await identityKeys.currentPublicIdentity()
let signature = try await identityKeys.sign(challenge)

let recovery = try await identityKeys.exportEncryptedRecovery(using: protection)
let restoredIdentity = try await identityKeys.importEncryptedRecovery(
  recovery,
  using: protection
)
```

- 반환 가능한 값은 public identity, signature와 opaque encrypted recovery payload다.
- export/import 중에도 raw private key는 TodoMateSync의 crypto/Apple Keychain adapter 밖으로
  나오지 않는다. import 성공은 복호화된 key를 바로 Keychain에 저장한 뒤 public identity만
  반환한다.
- recovery file과 QR은 같은 encrypted payload의 표현이다. recovery payload에는 Project
  plaintext key나 `KeyEnvelope`를 넣지 않는다.
- recovery password/code는 transient command 입력이다. 저장·로그·Accessibility ID·fixture
  filename에 남기지 않는다.

### Project encryption → ProjectKeyStore와 KeyEnvelope

Project plaintext key도 persistence repository가 읽고 쓰는 `Data`가 아니다. Sync runtime이
opaque handle을 통해 seal/open하고, Persistence는 암호화된 envelope와 비밀이 아닌 metadata만
보존한다.

```swift
let key = try await projectKeys.currentKey(
  projectID: projectID,
  epoch: operation.keyEpoch
)
let sealed = try await projectCrypto.seal(operation, using: key)

let envelope = try await projectKeys.makeEnvelope(
  projectID: projectID,
  epoch: nextEpoch,
  recipient: memberPublicKey
)
try await projectKeys.install(envelope, for: localIdentity)
```

- `ProjectKeyStore` port, opaque `ProjectKeyHandle`, `KeyEpoch`, encrypted `KeyEnvelope` 계약은
  SyncContracts에 둔다. Apple Keychain concrete adapter와 crypto runtime은 TodoMateSync가
  소유한다.
- `ProjectKeyHandle`과 plaintext key는 TodoMateSync 밖의 public result, Presentation State,
  GRDB row, Relay event와 로그로 전달하지 않는다.
- TodoMateGRDB는 `KeyEnvelope` ciphertext와 recipient/epoch/status metadata를 opaque하게
  저장할 수 있지만 key owner가 아니다.
- kick/leave 뒤 이전 epoch handle은 새 write/open 권한으로 재사용하지 않는다.

### Host composition → live local path와 deterministic scenario path

Host는 concrete type을 아는 유일한 조립 위치다. Application/Presentation에서 `.live`나
`.mock` 분기를 하지 않는다.

```swift
// TodoMate.app production target: Relay가 없는 local-only composition
let persistence = try TodoMateGRDB.production(configuration: appGroupConfiguration)
let keyStores = AppleKeyStores.production(accessGroup: keychainAccessGroup)
let clients = TodoMateApplication.live(
  projectStore: persistence.projectStore,
  observations: persistence.observations,
  sync: .localOnly
)

// 별도 UI scenario/debug test host target
let scenario = try TodoMateScenarioHost.make(
  .sharedProjectMultiChannel,
  persistence: .isolated(testID),
  relay: RelayMock(script: script),
  clock: .fixed(now),
  ids: .deterministic(seed: 42)
)
```

- MVP의 production-shaped remote adapter는 `RelayMock` 하나지만 Release `TodoMate.app`
  target에는 `RelayMock`이나 TestSupport product를 링크하지 않는다. RelayLive가 없는 Release
  composition은 별도 fake protocol 구현을 만들지 않고 local-only capability를 조립한다.
- Mock을 사용하는 POM journey는 별도 scenario/debug test host가 명시적으로 product를
  의존한다. 같은 app target에서 `#if DEBUG`로 import만 숨기는 방식은 target-level leakage를
  막지 못하므로 허용하지 않는다.
- future RelayLive는 같은 `RelayClient`를 구현하는 별도 target/product다. 현재 MVP package
  graph, Release app dependency와 완료 gate에는 넣지 않는다.
- Persistence package는 app writer와 Widget reader를 같은 public module에 두지 않는다.
  `TodoMateGRDBStorage`의 package-access core 위에 `TodoMateGRDB`와
  `TodoMateWidgetReadModel`을 별도 product/module로 만들고, Widget native target은 reader
  product만 링크한다. 따라서 writer/migration API 비노출은 naming convention이 아니라
  compiler와 dependency graph가 강제한다.

## Clean Architecture와 dependency composition

목표 구조는 Domain을 중심으로 dependency가 안쪽을 향하는 Clean Architecture를 따른다.
package 분리는 디렉터리 정리가 아니라 이 방향을 compile time에 강제하기 위한 장치다.

```text
SwiftUI / TCA Presentation
  -> TodoMateApplication typed client
    -> TodoMateDomain + TodoMateSyncContracts port

TodoMate.app composition root
  -> TodoMateGRDB concrete adapter
  -> SyncEngine / E2EE / AppleKeyStore concrete adapter
  -> 위 adapter를 Application client로 조립
```

- Domain은 entity, typed ID와 순수 policy를 소유하고 외부 framework를 알지 않는다.
- Application은 사용자의 command와 observation 흐름을 조정하지만 GRDB, Keychain, Relay
  구현을 알지 않는다.
- Persistence와 Sync는 안쪽 계층의 port를 구현하는 adapter다. concrete adapter끼리 직접
  import하지 않고 native Host가 runtime object graph를 연결한다.
- Presentation은 Application client만 소비한다. repository, database, crypto runtime을
  우회 호출하지 않는다.
- SwiftUI `Environment`는 theme, locale 같은 계층형 UI 설정이나 root Store 전달에 쓸 수
  있지만 service locator를 감추는 수단으로 사용하지 않는다.

### CartLog식 AppDependencies를 TodoMate composition root에 적용

[CartLog의 AppDependencies](https://github.com/hot666666/CartLog/blob/main/CartLog/Application/AppDependencies.swift)처럼
native Host는 concrete adapter를 한 번 조립하고, immutable dependency value를 AppFeature에
전달한다. `AppDependencies` 자체는 UI state나 canonical data가 아니므로 `@Observable` Store로
만들지 않는다.

```swift
@MainActor
struct AppDependencies {
  let projects: ProjectClient
  let todos: TodoClient
  let memos: MemoClient
  let chats: ChatClient
  let identity: IdentityClient
  let sync: SyncClient
  let preferences: PreferenceClient
}

enum LiveAppDependenciesFactory {
  @MainActor
  static func make(configuration: AppLaunchConfiguration) throws -> AppDependencies {
    // TodoMateGRDB, SyncEngine, E2EE와 AppleKeyStore를 여기서만 concrete type으로 조립한다.
  }
}
```

위 타입 목록은 목표 call site를 설명하는 logical capability 예시다. 실제 client signature는
소유 구현 이슈에서 테스트와 함께 확정한다. 다음 조립 규칙은 고정한다.

- `TodoMate.app`만 `LiveAppDependenciesFactory`와 concrete adapter를 안다.
- `AppDependencies`를 모든 View에 통째로 주입하지 않는다. AppFeature가 root에서 이를
  소비하고 child Feature에는 필요한 typed client만 TCA dependency로 제공한다.
- render-only View는 dependency container를 읽지 않고 value, `Binding`과 좁은 callback만
  받는다.
- AppIntent도 GRDB repository를 직접 받지 않고 Project-aware Application client를 받는다.
- launch mode는 `isMock: Bool`이나 임의 문자열이 아니라 exhaustive
  `AppLaunchConfiguration` / `UITestScenarioID`로 표현하며 알 수 없는 scenario는 fail closed한다.
- factory가 만든 mutable dependency는 actor 또는 명시적으로 동기화된 구현이어야 한다.
  공유 mutable mock에 근거 없이 `@unchecked Sendable`을 붙이지 않는다.

TCA call site는 전체 container가 아니라 Feature가 실제 사용하는 capability를 드러낸다.

```swift
@Reducer
struct ProjectTodoFeature {
  @Dependency(\.projectClient) var projects
  @Dependency(\.todoClient) var todos
}

let store = TestStore(initialState: ProjectTodoFeature.State()) {
  ProjectTodoFeature()
} withDependencies: {
  $0.projectClient = .testValue(/* deterministic fixture */)
  $0.todoClient = .testValue(/* deterministic fixture */)
}
```

### 실행 환경별 조립과 Mock 격리

| 실행 환경 | composition owner | 허용 dependency | 금지 사항 |
| --- | --- | --- | --- |
| Release app | `TodoMate.app`의 live factory | GRDB writer, Application clients, E2EE/AppleKeyStore, local-only Sync | `RelayMock`, PreviewSupport, TestSupport의 transitive link |
| render-only Preview | View-local fixture | value, binding, callback | DB/container 생성, shared mutable singleton |
| Feature Preview | 별도 PreviewSupport/debug host | in-memory typed client, fixed clock/ID | Release target dependency, 사용자 DB/UserDefaults 공유 |
| unit/TestStore | test target | 검사할 client만 dependency override | 전체 live container 생성 |
| Persistence integration | Persistence test target | test별 isolated in-memory GRDB | production App Group 파일 공유 |
| Sync/POM scenario | 별도 ScenarioHost/TestSupport | isolated GRDB, SyncEngine, RelayMock, deterministic key/clock/ID | RelayMock의 GRDB direct seed, unknown scenario fallback |

Preview와 test의 mock도 production Feature가 소비하는 것과 같은 typed client surface를
구현한다. 다만 multi-client sync 증거는 isolated GRDB + SyncEngine + RelayMock의 실제
production-shaped path를 통과해야 하며, client 결과나 GRDB row를 직접 주입한 fixture로
대체하지 않는다.

현재 `CoreDIContainer`, `PublicDIContainer`, `AppDIContainer`는 migration input이다.

1. concrete 생성 책임은 Host factory로 모은다.
2. repository/use case 묶음은 capability별 Application client로 축소한다.
3. legacy Store가 새 client를 소비하도록 과도기 adapter를 두되 새 View가 container를 직접
   참조하지 않게 한다.
4. TCA Feature 전환 뒤 legacy container와 production `Stub*` wiring을 제거한다.
5. Preview/mock 구현은 PreviewSupport/TestSupport/scenario host로 이동하고 Release dependency
   closure 검사를 추가한다.

따라서 새 `DIContainer` 계층을 하나 더 만드는 것이 목표가 아니다. 최종 결과는 native
Host의 작은 composition root, capability별 immutable client, target으로 격리된 test adapter다.

## 현재 compile-time baseline

현재 manifest와 Xcode product dependency는 다음 방향이다.

```text
Common                 -> Foundation + OSLog
TodoMateDomain         -> Common
TodoMateData           -> TodoMateDomain + Common + GRDB
TodoMate.app           -> Common + TodoMateDomain + TodoMateData
```

Widget native target은 현재 제거되어 있다. 후속 재도입 시에는 과거처럼 transitive import나
full writer product dependency에 기대지 않고 아래 목표 graph의 read-only facade만 소비한다.
`TodoMateDomain`의 `Common` dependency를 새 package에 그대로 복제하지 않는다.

## 목표 compile-time graph

화살표는 왼쪽 target이 오른쪽 target을 import할 수 있다는 뜻이다.

```text
TodoMateCore package
  TodoMateDomain          -> Foundation
  TodoMateSyncContracts   -> TodoMateDomain
  TodoMateApplication     -> TodoMateDomain + TodoMateSyncContracts
  TodoMateCoreTestSupport -> TodoMateDomain + TodoMateSyncContracts
                             + TodoMateApplication

TodoMatePersistence package
  TodoMateGRDBStorage     -> TodoMateDomain + TodoMateSyncContracts + GRDB
                             (package-internal target, public product 없음)
  TodoMateGRDB            -> TodoMateGRDBStorage + TodoMateDomain
                             + TodoMateSyncContracts
  TodoMateWidgetReadModel -> TodoMateGRDBStorage + TodoMateDomain

TodoMateSync package
  SyncEngine              -> TodoMateDomain + TodoMateSyncContracts
  RelayMock               -> TodoMateSyncContracts
  E2EE                    -> TodoMateDomain + TodoMateSyncContracts + crypto runtime
  AppleKeyStore           -> TodoMateSyncContracts + Security/CryptoKit
  TodoMateSyncTestSupport -> SyncEngine + RelayMock + test-only fixtures
  RelayLive (later)       -> TodoMateSyncContracts + network transport

TodoMatePresentation package
  TodoMateDesignSystem    -> SwiftUI
  TodoMatePresentation    -> TodoMateDomain + TodoMateApplication
                             + TodoMateDesignSystem + TCA

Native hosts
  TodoMate.app            -> Application + Presentation + GRDB + Sync production products
  TodoMateWidget          -> TodoMateWidgetReadModel only
  TodoMateScenarioHost    -> app products + RelayMock + Core/Sync TestSupport
```

이 graph에는 Persistence ↔ Sync, Application → concrete adapter, Presentation → Persistence/Sync
edge가 없다. Runtime object graph는 Host injection으로 연결하며 compile dependency를 역전시키지
않는다.

### Target별 public responsibility와 금지 import

| Target | public responsibility | 금지된 owner/import |
| --- | --- | --- |
| `TodoMateDomain` | typed ID, Project/Membership/Todo/Memo/Chat entity, author/lifecycle/authorization pure policy | `Common`, GRDB, TCA, SwiftUI, AppKit, Nostr, Security, OSLog |
| `TodoMateSyncContracts` | `ProjectOperation`, topic, envelope DTO, `RelayClient`, persistence/sync/key capability port | concrete GRDB, RelayMock/Live, Keychain, crypto implementation |
| `TodoMateApplication` | Project/Todo/Memo/Chat/Sync/Identity typed client와 orchestration | TCA, GRDB, SyncEngine, RelayMock/Live, Security |
| `TodoMateCoreTestSupport` | import 가능한 deterministic Domain/Application fixture와 client test value | Release app dependency, production source의 default mock |
| `TodoMateGRDBStorage` | package access schema/record/query core; public product로 노출하지 않음 | native host 직접 import, Screen/Store/TCA, plaintext key |
| `TodoMateGRDB` | app-only writer/migration factory, projection+outbox transaction, observation | Widget dependency, Screen/Store/TCA Action, Relay concrete, plaintext key |
| `TodoMateWidgetReadModel` | Widget 전용 snapshot DTO와 narrow read-only factory/query | writer/migration/outbox API, full repository surface, Sync concrete |
| `SyncEngine` / `E2EE` | outbox, subscription, seal/open, authorization/reconcile coordination | Application, Presentation, GRDB concrete type |
| `RelayMock` | 같은 RelayClient 계약의 deterministic transport script | GRDB direct write, Presentation fixture |
| `AppleKeyStore` | identity/Project key의 Keychain-backed capability | Presentation State, GRDB plaintext storage |
| `TodoMateDesignSystem` | SwiftUI semantic role/theme/style | Domain entity, TCA, GRDB, Relay, Security |
| `TodoMatePresentation` | TCA Feature/Screen/navigation, Application client dependency key | concrete persistence/sync/key adapter |
| `TodoMate.app` | Scene/Window/Panel/AppKit/Sparkle/AppIntent와 composition | domain policy/reconcile 구현 |

공개 API는 immutable `Sendable` value와 typed enum/ID를 기본으로 한다. actor나 lock으로
격리되지 않은 mutable class에 `@unchecked Sendable`을 붙여 target 경계를 넘기지 않는다.
Swift 6 native target 전환은 HOT6-56이 별도 수행하며 package 이동 PR에서 compiler setting과
광범위한 actor 수정을 섞지 않는다.

## Runtime owner와 secret owner

### Write와 receive

```text
Write
ViewAction
  -> Application typed command
  -> TodoMateGRDB projection + ProjectOperation outbox transaction
  -> SyncEngine outbox consumption
  -> E2EE seal
  -> RelayClient

Receive
RelayClient event
  -> outer format/signature/key-epoch preflight
  -> E2EE open
  -> membership + content-author authorization
  -> deterministic reconcile
  -> TodoMateGRDB projection commit
  -> observation
  -> TCA InternalAction
```

Presentation result, Relay ACK와 Darwin notification은 canonical data가 아니다. UI는 GRDB
observation을 소비하고, WidgetKit은 장기 observation 대신 narrow read-only snapshot을 만든다.

### Secret matrix

| 값 | runtime owner | 저장 가능 위치 | 노출 가능한 값 |
| --- | --- | --- | --- |
| identity private key | `AppleKeyStore` / identity crypto | Keychain only | public identity, signature |
| encrypted identity recovery | identity recovery runtime | 사용자가 선택한 file/QR payload | encrypted payload metadata |
| Project plaintext key | `ProjectKeyStore` / E2EE runtime | Keychain-backed Sync adapter | key epoch/status summary |
| `KeyEnvelope` ciphertext | SyncContracts DTO | GRDB/Relay opaque payload | recipient/epoch/status metadata |
| Relay endpoint/credential | future RelayLive host config | future secure host config | connection summary only |

Presentation과 Persistence는 identity private key 또는 Project plaintext key를 소유하지 않는다.
로그는 key, recovery password, plaintext envelope payload를 받지 않는 typed metadata API를 쓴다.

## Mock, fixture와 Release linkage

`Stub*`, Preview fixture, deterministic Relay runtime은 서로 다른 용도다.

- Domain production source에는 `StubRepository`, `StubUseCase`, `.stub/.dummy` fixture를 두지
  않는다. 여러 package/scenario host가 재사용할 fixture는 non-Release product인
  `TodoMateCoreTestSupport`로, 한 test target만 쓰는 helper는 그 test target source로 옮긴다.
- `RelayMock`은 production-shaped transport contract 구현이지만 배포용 Relay가 아니다.
  Sync integration test와 scenario host만 product dependency를 가진다.
- `TodoMateSyncTestSupport`는 scripted clock/ID/event/failure와 multi-client harness를 소유한다.
  `SyncEngine` production target은 TestSupport를 import하지 않는다.
- PreviewSupport는 Presentation/DesignSystem의 debug 또는 test-only target이다. Feature public
  API에 fixture factory를 넣지 않는다.
- Xcode/SwiftPM graph 검사에서 Release `TodoMate.app` target의 transitive dependency closure에
  `TodoMateCoreTestSupport`, `RelayMock`, `TodoMateSyncTestSupport`, PreviewSupport가 없어야 한다.
- dependency 이름 검사만으로는 production module 안 fixture를 찾을 수 없다. Core production
  source와 Release app source에 `Stub*`, `.stub`, `.dummy`가 남지 않았는지도 별도 source gate로
  검사한다. migration 중 필요한 legacy compatibility 구현은 app-local expiring allowlist에
  정확한 file/symbol과 제거 issue를 기록하며, HOT6-32 완료 시 allowlist도 0건이어야 한다.
- `TodoMateScenarioHost`는 잘못된 `UITestScenarioID`를 default fixture로 바꾸지 않고 launch 전에
  fail closed한다.

HOT6-26은 위 규칙을 canonical `just check-module-boundaries` recipe로 만든다. 이 recipe는
resolved SwiftPM/Xcode target graph와 production source를 함께 검사해 다음에서 fail closed한다.

1. Release `TodoMate.app` dependency closure에 Core/Sync TestSupport, RelayMock 또는
   PreviewSupport product가 존재한다.
2. Widget native target이 `TodoMateWidgetReadModel` 밖 persistence product/module을 direct
   dependency/import하거나 `TodoMateGRDB` writer facade를 링크한다. reader product의
   implementation dependency로 들어오는 non-product `TodoMateGRDBStorage`는 허용하되 Widget
   source가 직접 import할 수 없어야 한다.
3. Domain/Application production source에 fixture symbol이 있거나 Release app source에
   제거 issue가 없는 legacy compatibility symbol이 있다.

HOT6-26에서는 app-local compatibility allowlist와 각 제거 issue를 machine-readable input으로
허용하지만 Core production source allowlist는 허용하지 않는다. HOT6-32는 같은 recipe를
allowlist 없이 실행해 0건을 증명한다.

## 현재 producer/consumer → 목표 owner

현재 source에는 Project/Membership/ChatChannel/ProjectOperation/RelayClient/key port가 아직
없다. 아래 표의 “목표”는 파일 이동 완료가 아니라 후속 구현 owner다.

| 현재 producer | 현재 주요 consumer | 목표 owner와 migration |
| --- | --- | --- |
| `TodoMateDomain/Sources/TodoMateDomain/Entity/Todo.swift`, `Memo.swift`, `DeletedItem.swift`, `TodoQuery.swift` | GRDB record/repository, app Store/ViewModel, AppIntent | `TodoMateDomain`; HOT6-24 mapping 뒤 HOT6-26이 ProjectID/authorID를 가진 model로 전환 |
| `TodoMateData/Sources/TodoMateData/GRDB/LocalAuthorID.swift`, `Models/TodoRecord.swift`/`MemoRecord.swift`의 `ownerID`, `LegacySwiftDataImporter.swift`, `GRDBAppGroupMigration.swift` | legacy Todo/Memo import와 기존 DB migration, author filter | HOT6-24가 alias→`ContentAuthorID` 보존표를 고정하고 HOT6-26이 Domain typed ID와 GRDB migration에 같은 규칙 적용 |
| `TodoMateDomain/Sources/TodoMateDomain/Entity/User.swift`, `Group.swift`, `GroupMessage.swift`, session entity | Session/Group/Message Store와 legacy UI | `Project`, `Membership`, `ChatChannel`, `Message`의 legacy input; HOT6-24/26/36이 보존·대체 경계를 소유 |
| `TodoMateDomain/Sources/TodoMateDomain/Protocol/TodoRepository.swift`, `MemoRepository.swift`, `DeletedItemsRepository.swift` | GRDB 구현과 local use case | persistence capability는 SyncContracts/Application port, 구현은 `TodoMateGRDB`; Domain에는 pure policy만 유지 |
| `TodoMateDomain/Sources/TodoMateDomain/Protocol/`의 legacy User/Group/Message/Auth/Connectivity protocol | `PublicDIContainer`, group Store | 새 public Core API로 승격하지 않고 Project client/RelayClient 전환 중 제거 |
| `TodoMateDomain/Sources/TodoMateDomain/UseCase/**` | Core/PublicDIContainer와 legacy Store | pure invariant는 Domain, orchestration과 typed client는 `TodoMateApplication`; fixture implementation은 TestSupport |
| `TodoMateDomain/Sources/TodoMateDomain/UseCase/Todo/SyncTodayTodosUseCase.swift` | `AppDIContainer`, GroupFeed refresh | 제거 대상 local/remote repository LWW bridge; 목표 sync는 `SyncEngine` + `RelayClient` |
| `TodoMateData/Sources/TodoMateData/GRDB/GRDBDatabase.swift`, migrations, records, repositories, change center | CoreDIContainer와 local Store | package-internal `TodoMateGRDBStorage` + app writer facade `TodoMateGRDB`; native app에는 facade만 노출 |
| `TodoMateData/Sources/TodoMateData/GRDB/GRDBAppGroupMigration.swift`, `LegacySwiftDataImporter.swift` | app의 shared DB open path | storage core를 쓰는 `TodoMateGRDB` app-only writer/migration facade에서만 실행 |
| `TodoMateData/Sources/TodoMateData/GRDB/GRDBReadOnlyDatabase.swift`, `Repositories/GRDBTodoReader.swift` | 현재 cross-process probe; 후속 Widget 재도입 | `TodoMateWidgetReadModel`의 narrow snapshot facade; package-internal storage만 공유하고 writer/migration API는 module 수준에서 비노출 |
| `TodoMateData/Sources/TodoMateData/`의 CalendarDay/UserDefaults sidebar/message/legacy import adapter | app DI와 legacy Store | calendar pure policy는 Domain/Application, UI preference는 Presentation/app adapter, migration state는 migration-only adapter |
| `TodoMate/Models/TodoBoardStore.swift`, `MemoStore.swift`, calendar/trash ViewModel | Home/Memo/Overlay/MenuBar | HOT6-9 이후 `TodoMatePresentation` TCA Feature로 점진 교체; CoreDIContainer init 제거 |
| Session/Todo/Message Store와 GroupFeedViewModel | Login/GroupFeed/Chat | Project/Membership/Chat Feature로 교체; remote repository를 알지 않음 |
| `NavigationManager.swift` | MainView/HomeView | Presentation navigation state |
| `CoreDIContainer`, `PublicDIContainer`, `AppDIContainer`, `TodoMateApp.swift` | 전체 app composition | concrete 조립은 Host, consumer API는 typed Application client로 축소 |
| `AppDelegate.swift`, `WindowManager/**` | Scene, overlay, Sparkle, hotkey | `TodoMate.app`; TCA intent와 AppKit callback 사이 bridge |
| `TodoMate/AppIntent/**` | Shortcuts/AppIntent | `TodoMate.app`; repository 대신 Project-aware Application client 소비 |
| 제거된 `TodoMateWidget/**` | 후속 WidgetKit 재도입 | Widget host + `TodoMateWidgetReadModel` narrow read-only projection; writer product 직접 dependency 금지 |
| `AppDIContainer+Mocks.swift`, `TodoMateApp+Debug.swift`, Domain `Stub*`, `TodoMateApp.composeContainer()`의 Release `Stub*Repository`/`StubAuthService` 생성 | Preview/screenshot/debug와 현재 Release legacy group wiring | HOT6-26이 reusable fixture를 `TodoMateCoreTestSupport`로 옮기고 Release가 그 product를 링크하지 않게 함. 필요한 app-local compatibility symbol은 제거 issue allowlist로 한정하고 HOT6-28/29/31/36/37이 각 consumer를 typed client로 교체, HOT6-32가 Release source/dependency zero gate를 검증 |

### Legacy author ID 보존 정책

현재 `LocalAuthorID`는 `""`와 `EntityConstant.User.stubId`인 `"testUser"`를
`User.local.id`인 `"local-user"`로 canonicalize한다. 이 셋만 기존 단일 local actor의
placeholder alias 집합이다.

- HOT6-24는 이 alias 집합을 `ContentAuthorID` before/after fixture 표에 기록한다.
- 그 밖의 non-empty author/owner ID는 서로 다른 작성자로 그대로 보존한다. Project Owner라는
  이유로 다른 작성자의 ID를 local author에 흡수하거나 mutation 권한을 얻지 않는다.
- HOT6-26은 legacy importer, existing GRDB migration과 새 Project schema에 같은 mapping을
  적용하고 alias 세 경우, distinct foreign author, 재실행, other-author update/delete 거부를
  Data test로 고정한다.
- 향후 Keychain identity와 legacy local author를 연결해야 한다면 별도 provenance가 있는
  명시적 migration으로 수행한다. DB open이나 sign-in 시 임의로 기존 author ID를 rewrite하지
  않는다.

### `Common`은 새 우회 dependency가 아니다

현재 `TodoMateDomain -> Common` edge는 목표 graph에서 제거한다. `Common`을 통째로 Core에
옮기지 않고 실제 owner로 분해한다.

| 현재 Common source | 목표 owner |
| --- | --- |
| `AppEnvironment.Container` | Host가 만든 persistence configuration; `TodoMateGRDB`에 value로 주입 |
| 제거된 `AppEnvironment.Widget`, `AppSceneID` | Widget kind는 재도입 시 host가 소유; AppSceneID는 native app host |
| `Log` (`OSLog`) | host/platform logging adapter; Domain/SyncContracts에는 metadata port만 필요한 경우 별도 정의 |
| `UserDefaults+`, `UserDefaultsKey` | Presentation preference 또는 host/migration adapter별 분리 |
| `Date+` formatting | DesignSystem/Presentation; pure calendar 계산은 주입된 `Calendar`를 쓰는 Domain policy |

`TodoMateDomain/Sources/TodoMateDomain/UseCase/Todo/SyncTodayTodosUseCase.swift`의
`Date.dayRange` 의존은 pure calendar input으로 바꾸고,
`TodoMateDomain/Sources/TodoMateDomain/UseCase/Todo/UpdateTodoUseCase.swift`의 미사용
`Common` import는 해당 migration slice에서 제거한다.

## 충돌하지 않는 migration slice

공유 `Package.swift`, `project.pbxproj`, GRDB migration은 동시에 둘 이상의 이슈가 수정하지
않는다. source 디렉터리가 달라도 shared manifest writer는 한 이슈만 가진다.

| 순서 / issue | 소유 파일·결과 | 명시적 비소유와 gate |
| --- | --- | --- |
| HOT6-21 | 이 문서와 `app-architecture.md` 링크 | package 생성, schema, TCA/Sync 구현 없음 |
| HOT6-56 | `TodoMate.xcodeproj/project.pbxproj`와 native target concurrency fix | package 이동/새 product wiring과 분리; HOT6-26의 native host wiring/merge 전에 병합 |
| HOT6-24 | legacy entity mapping 문서와 before/after fixture 표 | production GRDB migration/repository를 수정하지 않음 |
| HOT6-26 | `TodoMateCore`/`TodoMatePersistence` 최초 physical bootstrap의 단일 manifest owner. `TodoMateDomain`/`SyncContracts`/`Application`/`CoreTestSupport`, 분리된 GRDB storage/writer/Widget reader target, typed Project/author ID와 의미 없는 opaque `ChatChannelID`/`MessageID` primitive, Project/Todo/Memo Application client, Project/Membership/Todo/Memo schema와 read projection | Chat entity/client/schema/policy는 HOT6-36, legacy 실행은 HOT6-27, Relay/Sync 구현은 HOT6-33. Domain fixture는 CoreTestSupport로 이동하고 Release legacy compatibility는 expiring owner allowlist로 제한 |
| HOT6-8 | Screen/View/route catalog 문서 | package/public client 구현 없음 |
| HOT6-9 | `TodoMatePresentation` package/AppFeature shell, HOT6-26 Project/Todo/Memo client의 TCA dependency-key adapter | Core/Application public API와 GRDB/Sync/Keychain concrete를 수정하지 않음; HOT6-8과 HOT6-26 뒤 시작 |
| HOT6-33 | 기존 `TodoMateSyncContracts` target의 Relay/topic/envelope/`RelayClient` 확장, `TodoMateSync` 최초 manifest, `SyncClient`, SyncEngine/RelayMock/TestSupport와 `just test-sync` | GRDB projection 직접 쓰기와 HOT6-7 outbox schema를 선점하지 않음 |
| HOT6-34 | SyncContracts의 `IdentityKeyStore`, Application의 `IdentityClient`, encrypted recovery payload, Apple Keychain/identity crypto target | Project key/KeyEnvelope/rotation은 HOT6-35; Sync manifest bootstrap 뒤 추가 |
| HOT6-35 | SyncContracts의 `ProjectKeyStore`/`KeyEnvelope`/epoch port와 E2EE/key rotation runtime | membership policy/outbox 조립은 HOT6-47/HOT6-7이 소유 |
| HOT6-36 | HOT6-26의 opaque ID 위에 ChatChannel/Message 관계·policy Domain과 GRDB projection, Application `ChatClient` | Presentation Chat screen은 HOT6-37, Relay/E2EE 연결은 HOT6-38 |
| HOT6-47 | author matrix, membership state machine, conflict policy/fixture seam | HOT6-26 schema나 HOT6-7 reconcile을 선점하지 않음; Todo tie-breaker public/schema 고정 직전 review |
| HOT6-49 | Presentation package 안 SwiftUI-only DesignSystem target | Core/Sync/Persistence import와 기존 helper 일괄 삭제 없음; HOT6-9 뒤 시작 |
| HOT6-28/29/31/36/37 | Project/Todo/Memo/Chat별 Release legacy Store와 app-local compatibility consumer를 typed client/Feature로 교체 | 다른 capability의 compatibility symbol을 함께 이동하지 않음 |
| HOT6-32 | Relay 없는 full local journey와 Release source/dependency closure의 fixture/mock allowlist 0건 검증 | 앞 이슈의 누락 구현을 integration fixture로 우회하지 않음 |

### Typed Application client 생산 순서

Presentation consumer가 먼저 임의의 public client를 만들지 않도록 producer를 단계별로
고정한다.

| client surface | 최초 producer | 최초 consumer / 완료 시점 |
| --- | --- | --- |
| `ProjectClient`, `TodoClient`, `MemoClient` | HOT6-26 `TodoMateApplication` | HOT6-9 TCA dependency adapter; HOT6-28/29/31에서 live Feature 소비 |
| opaque `ChatChannelID`, `MessageID` | HOT6-26 `TodoMateDomain` | HOT6-33 typed Chat topic; HOT6-36이 entity 관계·schema·policy를 추가 |
| TCA `DependencyKey`/test value adapter | HOT6-9 `TodoMatePresentation` | HOT6-10 이후 child Feature |
| `SyncClient`와 adapter-neutral `RelayClient` | HOT6-33 Application/SyncContracts | HOT6-7 outbox/reconcile과 scenario host |
| `IdentityClient` / `IdentityKeyStore` | HOT6-34 Application/SyncContracts | identity/recovery flow |
| `ProjectKeyStore`, `KeyEnvelope`, epoch crypto port | HOT6-35 SyncContracts | E2EE runtime과 HOT6-7/HOT6-38 integration |
| `ChatClient` | HOT6-36 Application | HOT6-37 Chat Feature; HOT6-38 remote path |

HOT6-26 이전의 HOT6-9가 Project client signature를 고정하거나 HOT6-9가 아직 없는
`ChatClient`를 placeholder로 만들지 않는다. HOT6-32는 이 표의 구현을 검증하는 통합 owner이지
누락된 public API의 최초 producer가 아니다.

다음 세 compile-time/merge 선행조건은 live Linear `blocked by` 관계와 각 이슈 설명에
반영되어 있다. 후속 scope를 바꾸지 않는 한 이 관계를 유지한다.

1. HOT6-9는 HOT6-26의 Core typed ID/Application target bootstrap 뒤 시작한다.
2. HOT6-34는 HOT6-33의 Sync package/`just test-sync` bootstrap 뒤 target을 추가한다.
3. HOT6-26은 HOT6-56의 native Swift 6/concurrency 정리 뒤 native host product를 wiring하고
   병합한다. 별도 worktree의 문서/fixture 준비는 병렬로 할 수 있다.

HOT6-47은 지금 author matrix와 reversible fixture를 작성할 수 있다. 다만 SyncEngine
permutation test와 production reconcile 완료 증거는 HOT6-26/33의 구현을 소비해야 하며,
남은 Todo same-field tie-breaker를 protocol/schema에 고정하기 직전에 사용자 review를 받는다.

### 독립 build/test와 host 통합 순서

각 slice는 producer부터 consumer 순으로 검증한다. 앞 계층의 성공을 뒤 계층 증거로 부르지
않는다.

```text
1. dump-package + forbidden-import / Release dependency scan
2. TodoMateDomain unit test
3. TodoMateSyncContracts compile/contract test
4. TodoMateApplication unit test
5. TodoMateGRDB migration/transaction/observation test
6. SyncEngine + RelayMock multi-client integration test
7. TodoMateDesignSystem build/preview contract
8. TodoMatePresentation TestStore
9. certificate/provisioning-free app + Widget build
10. 필요한 signed app/runtime, POM journey와 screenshot catalog
```

목표 canonical recipe는 package 생성 이슈가 `justfile`에 함께 추가한다. 임시 raw
`swift build/test` 성공만으로 후속 package gate를 대체하지 않는다.

## HOT6-21 검증 범위

이 문서는 현재 manifest를 바꾸지 않으므로 다음으로 baseline과 문서 자체를 검증한다.

```bash
swift package dump-package --package-path Common
swift package dump-package --package-path TodoMateDomain
swift package dump-package --package-path TodoMateData
git diff --check
```

추가로 relative Markdown link가 실제 repository path를 가리키는지 확인한다. 이 문서에는
render하지 않은 Mermaid를 넣지 않았다. app build는 문서-only 변경의 완료 증거가 아니다.
