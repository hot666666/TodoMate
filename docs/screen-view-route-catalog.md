# Project-first Screen–View와 route catalog

> 상태: 구현 전 handoff. 이 문서는 `dev@f3b6fb7617481bca36a405ea818a1a7023764ed1`
> 소스에서 확인한 legacy 화면을 Project-first 목표 계층에 매핑한다. SwiftUI/TCA, route type,
> POM과 AccessibilityID가 이미 구현됐다는 의미가 아니다.
>
> Canonical source:
> [TodoMate Future Core Architecture v0.2](https://linear.app/hot6/document/todomate-future-core-architecture-v02-05b1682c21b0),
> [HOT6-48 Semantic UI Contract v0.8](https://linear.app/hot6/document/hot6-48-semantic-ui-contract-and-product-review-brief-v08-ac217d38e7ed)

## 문서의 결정 범위

이 문서는 다음 구현자가 같은 이름과 ownership을 사용하도록 screen tree, typed route,
selection, effect lifetime과 UI test handoff를 고정한다.

- Project는 유일한 최상위 workspace다. 개인 사용도 멤버 한 명의 Project다.
- Sidebar의 reorderable Project 목록에서 `ProjectID`를 직접 선택한다. Workspace picker는
  MVP route에 없다.
- Todo, Memo와 Chat은 선택된 Project의 section이다.
- Local, Hosted, Shared, Offline과 Detached는 새 화면이나 route identity가 아니라 같은
  Project의 topology, sync와 access state다.
- route와 selection은 표시 이름, Relay URL 또는 Mock/Live adapter 이름이 아니라 opaque
  typed ID를 사용한다.
- Screen은 scoped TCA Store와 navigation/effect lifetime을 소유하고, render-only View는
  표시 값, `Binding`과 좁은 callback만 받는다.

`HOT6-48`의 R2 Smart View/mini Calendar scope와 R4 final contrast/density는 여전히 사용자
review 대상이다. 이 문서는 두 항목의 기본값, 노출 여부나 visual token을 결정하지 않는다.
R1 Project direct selection, R3 Inspector presentation과 R5–R8의 이미 확정된 계약만
소비한다.

## Typed identity와 route

`ProjectID`, `TodoID`, `MemoID`와 `ChatChannelID`는 `HOT6-26`이 제공할 opaque Domain
primitive다. 기존 문서와 Linear AC의 짧은 이름 `ChannelID`는 이 catalog에서
`ChatChannelID`를 뜻한다. ID의 raw representation은 Presentation과 POM의 public API가
아니다.

아래 코드는 call-site를 설명하는 목표 shape다. 실제 선언과 package product는 각 owner
issue가 추가한다.

```swift
enum AppRouteIntent: Equatable, Sendable {
  case project(ProjectID)
  case todo(projectID: ProjectID, todoID: TodoID)
  case memo(projectID: ProjectID, memoID: MemoID)
  case chat(projectID: ProjectID, channelID: ChatChannelID)
  case members(ProjectID)
  case projectSettings(ProjectID)
  case detachedCopy(ProjectID)
  case identityRecovery
}

enum ProjectSection: Equatable, Sendable {
  case todo
  case memo
  case chat
}
```

이 route shape의 규칙은 다음과 같다.

- item route는 항상 부모 `ProjectID`를 함께 요구한다. optional dummy ID나 현재 singleton
  group을 암묵적으로 참조하지 않는다.
- `.project`는 `AppFeature.selectedProjectID`를 바꾸고, `.todo`는 해당 Workspace의 Todo
  section과 `ProjectWorkspaceFeature.selectedTodoID`를 함께 설정한다. projection child는 이
  selection을 복제하지 않는다.
- typed ID만으로 item이 해당 Project 소속인지 컴파일 시간에 증명할 수는 없다. Application
  client가 관계를 검증하고 mismatch/not-found이면 route를 실행하지 않는다.
- Sidebar reorder는 route action이 아니다. 사용자별 local preference에 `[ProjectID]`
  순서만 저장하며 ProjectID, 이름, content, membership, topology와 sync state를 바꾸지 않는다.
- `ProjectWorkspaceFeature`의 `selectedSection`은 navigation state다. section control의 최종
  visual 표현은 route/ownership과 별개다.
- Relay URL은 hosting 설정 값일 수 있지만 route identity가 아니다. `RelayMock`,
  `MockRelayClient`, `RelayLive` 같은 adapter 이름도 production State와 UI 문구에 넣지 않는다.
- Command Palette의 Project/Todo/Memo 검색 route는 같은 `AppRouteIntent` 의미를 사용한다.
  Chat 검색 포함 여부, 기본 Project search scope와 filter 표현은 이 문서에서 추가로 정하지
  않는다.

Project 상태는 다음 다섯 independent semantic input으로 전달한다.

| Input | Presentation이 소비하는 의미 | 금지되는 축약 |
| --- | --- | --- |
| topology | `localOnly`, `hosted`, `shared` | Relay URL이나 adapter 이름으로 topology 추론 |
| access | `editable`, `detachedReadOnly(reason, lastSyncedAt)` | `isReadOnly`만 보고 원인/허용 action 추론 |
| sync | `notApplicable`, `syncing`, `synced`, `offline`, `error` | `isOnline` Boolean 하나, pending outbox를 sync에 합침 |
| outbox | `notApplicable`, `empty`, `pending`, `failed` | offline과 pending/failed delivery를 같은 상태로 합침 |
| content authority | self-authored allowed actions, foreign-content read-only | `isOwner`에서 content edit/delete 권한 파생 |

Local Project의 sync는 `notApplicable`일 수 있고, Shared Project는 `offline + empty outbox`와
`offline + pending outbox`가 모두 가능하다. membership 관리 action은 위 content-authority와
별도인 typed capability로 전달한다. Presentation은 이 input을 조합해 Local/Syncing/Synced/
Offline/Error summary와 outbox detail을 표현할 뿐 Relay, key와 repository concrete adapter를
조회하지 않는다.

## Canonical screen tree

```text
TodoMateApp                                          TodoMate.app host
├─ Main Window                                      Scene/Window host
│  └─ AppShellScreen                                AppFeature
│     ├─ ProjectSidebarScreen                       ProjectListFeature
│     │  ├─ Project list/reorder
│     │  └─ IdentityProfileView
│     │     └─ IdentityRecoveryScreen               IdentityFeature destination
│     └─ ProjectWorkspaceScreen(ProjectID)          ProjectWorkspaceFeature
│        ├─ ProjectTodoScreen                       TodoFeature
│        │  ├─ KanbanFeature → KanbanView
│        │  ├─ TodoCalendarFeature → TodoCalendarView
│        │  ├─ TodoTimelineFeature → TodoTimelineView
│        │  ├─ TodoInspectorView
│        │  └─ TodoEditorPresentation
│        ├─ ProjectMemoScreen                       MemoFeature
│        │  ├─ MemoCollectionView
│        │  ├─ MemoEditorView
│        │  └─ MemoRevisionHistoryPresentation
│        ├─ ProjectChatScreen                       ChatFeature
│        │  ├─ ChannelListView
│        │  ├─ ConversationView
│        │  ├─ ChatComposerView
│        │  └─ Channel metadata actions/presentation
│        ├─ ProjectMembersScreen                    ProjectMembersFeature
│        └─ ProjectSettingsScreen                   ProjectSettingsFeature
├─ Command Palette Panel                            CommandPaletteFeature + NSPanel host
│  ├─ Search
│  └─ Quick Capture
└─ Menu Bar Extra                                   MenuBarFeature + host surface
```

`Screen ≈ Feature`는 ownership heuristic이지 기계적인 1:1 규칙은 아니다. 예를 들어
`ProjectSidebarScreen`은 독립 window가 아니므로 POM에서는 `AppShellPageScreen`의
`ProjectSidebarComponent`로 표현할 수 있다. Kanban/Calendar/Timeline은 별도 canonical
entity source나 selection owner가 아니지만 drag state, visible month, scale/pagination 같은
transient state 때문에 `KanbanFeature`, `TodoCalendarFeature`, `TodoTimelineFeature`를 우선
유지한다. 구현 뒤 순수 value/callback render만 남는 child만 `TodoFeature`로 fold할 수 있다.

## Screen, Feature와 PageScreen catalog

| Canonical Screen/surface | TCA owner | 핵심 identity/state | render-only child | POM handoff |
| --- | --- | --- | --- | --- |
| `AppShellScreen` | `AppFeature` | one authoritative selected `ProjectID?`, typed route, main-window activation intent | app shell/chrome | `AppShellPageScreen` |
| `ProjectSidebarScreen` | `ProjectListFeature` | Project rows, parent selection binding/delegate, local `[ProjectID]` order, identity-profile delegate | Project row/list, `IdentityProfileView` | `ProjectSidebarComponent` |
| `ProjectWorkspaceScreen` | `ProjectWorkspaceFeature` | scoped `ProjectID`, selected section, one authoritative `TodoID?`, five semantic Project inputs, destination/child lifetime | toolbar, section control, sync/outbox status, Detached banner | `ProjectWorkspacePageScreen` |
| `ProjectTodoScreen` | `TodoFeature` | `ProjectID`, projection mode/filter, parent Todo selection binding/action delegate; no `TodoID?` copy | `TodoInspectorView`, editor content | `ProjectTodoPageScreen` |
| Kanban surface | `KanbanFeature` | drag/drop, hover and projection-local transient state; no Todo entity copy | `KanbanView` | `KanbanComponent` |
| Calendar surface | `TodoCalendarFeature` | visible month/date and calendar-local transient state; no Todo entity copy | `TodoCalendarView` | `TodoCalendarComponent` |
| Timeline surface | `TodoTimelineFeature` | visible range/scale/pagination and timeline-local transient state; no Todo entity copy | `TodoTimelineView` | `TodoTimelineComponent` |
| `ProjectMemoScreen` | `MemoFeature` | `ProjectID`, selected `MemoID?`, editor draft, Revision History/conflict-version presentation | `MemoCollectionView`, `MemoEditorView`, revision rows | `ProjectMemoPageScreen` + revision-history component |
| `ProjectChatScreen` | `ChatFeature` | `ProjectID`, selected `ChatChannelID?`, conversation cursor, composer state, create/creator-edit/Owner-archive capabilities | `ChannelListView`, `ConversationView`, `ChatComposerView`, channel metadata content | `ProjectChatPageScreen` + channel components |
| `ProjectMembersScreen` | `ProjectMembersFeature` | `ProjectID`, membership projection, allowed management actions and lifecycle presentation | member list/row, invite/transfer/leave/kick presentation content | `ProjectMembersPageScreen` |
| `ProjectSettingsScreen` | `ProjectSettingsFeature` | `ProjectID`, Project settings, hosting/encryption summary, lifecycle presentation | settings sections | `ProjectSettingsPageScreen` |
| `IdentityRecoveryScreen` | `IdentityFeature` | Sidebar profile delegate가 여는 global identity route; no Project plaintext key or `KeyEnvelope` | encrypted file/QR export/import views | `IdentityRecoveryPageScreen` |
| `Command Palette Panel` | `CommandPaletteFeature` | presentation, search/quick-capture mode, query, result selection, nested draft | palette result/capture views | `CommandPalettePageScreen` in `HOT6-44` |
| `Menu Bar Extra` | `MenuBarFeature` | Project-aware summary/actions supplied by typed clients | menu rows | reusable host/component object if a journey needs it |

The Feature owns semantic state; the macOS host owns only `Scene`, `Window`, `NSPanel`, AppKit
focus/window events, global shortcut registration and `openWindow`. A PageScreen owns UI lookup,
wait, action, assertion and transition; it never reads TCA State.

## Screen–View call site

`ProjectWorkspaceScreen` creates or receives a scoped child Store. The child Screen converts Store
state into display values and typed callbacks. A projection View does not look up DI, repository,
TCA Store or global navigation from `Environment`.

```swift
let todoStore = workspaceStore.scope(state: \.todo, action: \.todo)
let selectedTodoID = workspaceStore.binding(
  get: \.selectedTodoID,
  send: ProjectWorkspaceFeature.Action.todoSelected
)
ProjectTodoScreen(store: todoStore, selectedTodoID: selectedTodoID)

// ProjectTodoScreen.body
KanbanView(
  model: todoStore.kanban.projection,
  selectedTodoID: selectedTodoID,
  onDragChanged: { drag in
    todoStore.send(.kanban(.dragChanged(drag)))
  },
  onMove: { todoID, status in
    todoStore.send(.kanban(.moveRequested(todoID, status)))
  }
)
```

이 예시에서 `ProjectWorkspaceFeature`가 authoritative `TodoID?`와 child destination lifetime을
소유하고, `ProjectTodoScreen`/`TodoFeature`는 scoped Store, observation과 Todo action을
소유한다. Todo child는 parent가 전달한 `Binding<TodoID?>`/action delegate를 사용하며 State에
selection을 복제하지 않는다. `KanbanFeature`는 Todo entity를 복제하지 않고 drag/drop
transient state와 action을 줄이며 `KanbanView`는 전달받은 value를 그린다.
`TodoCalendarFeature`와 `TodoTimelineFeature`도 projection-local state만 소유하고 같은 parent
selection binding을 사용한다.
`Bool` 조합인 `isOffline`/`isDetached`/`isOwner`로 action을 추론하지 않고 Application이
계산한 topology/access/sync/outbox/content-authority input과 별도 membership capability를
소비한다.

### Effect lifetime

- Project-scoped observation/subscription effect는 `ProjectID`로 식별하고 route가 다른
  Project로 바뀌거나 Screen lifetime이 끝나면 취소한다.
- Channel conversation effect는 `ProjectID + ChatChannelID`로 식별한다. Channel 전환 뒤
  이전 response가 새 conversation State를 바꾸지 않는다.
- save/send/member mutation은 typed Application client를 호출한다. 성공 entity를 TCA
  State에 두 번째 canonical copy로 직접 삽입하지 않고 GRDB observation을 기다린다.
- Screen의 reducer/effect가 error, retry와 cancellation을 소유한다. render-only View의
  `.task`나 `onAppear`가 repository observation을 시작하지 않는다.
- AppKit host callback은 typed View/Delegate Action으로 들어오며 host가 Feature State를
  별도로 복제하지 않는다.

## 같은 TodoID의 projection과 selection

`ProjectWorkspaceFeature.State.selectedTodoID: TodoID?`가 Todo selection의 단일 owner다.

```text
Kanban select ─┐
Calendar select ──> Workspace.selectedTodoID ───────────> Todo Inspector
Timeline select ─┘                                      └─> Todo Editor
```

- mode를 Kanban → Calendar → Timeline으로 바꿔도 `selectedTodoID`를 새 ID나 별도 View-local
  selection으로 복제하지 않는다.
- 세 projection과 Inspector는 같은 GRDB observation snapshot의 Todo를 `TodoID`로 찾는다.
  Calendar/Timeline용 별도 Todo entity source를 만들지 않는다.
- Kanban은 workflow/status projection, Calendar는 planned start/due projection, Timeline은
  actual started/completed/reopened history projection이다. planned time과 actual event를 같은
  필드나 의미로 취급하지 않는다.
- drag/drop, 일정 변경과 실행 기록 action은 `TodoID`를 전달한다. 화면은 optimistic canonical
  entity를 임의로 만들지 않고 command/outbox transaction 뒤 observation으로 갱신한다.
- Todo가 tombstone되거나 현재 Project에 속하지 않는다고 확인되면 Feature가 selection과
  Inspector/editor presentation을 함께 정리한다.
- `TodoEditorPresentation`은 Workspace 안의 편집 수명주기다. 선택된 Todo Inspector와 내용을
  공유할 수 있지만 global Command Palette Panel의 수명주기와 합치지 않는다.

### Inspector presentation contract

Inspector content와 `selectedTodoID`는 presentation 방식이 바뀌어도 동일하다.

- wide에서는 native inspector column을 사용한다.
- 736–1023 medium에서는 `NSWindow` frame을 바꾸지 않는 host-bounds trailing edge drawer를
  사용한다.
- 360–735 narrow에서는 explicit sheet 또는 detail route를 사용한다.
- 분기는 macOS size class 가정이 아니라 실제 container geometry를 사용한다.
- Inspector show/hide는 `NSWindow` frame을 변경하지 않는다.

이 R3 계약의 semantic destination은 `ProjectWorkspaceFeature`가, projection/detail content는
`TodoFeature`가 제공한다. drawer adapter와 final surface token은 각 downstream owner가
구현하며 R2/R4 선택을 여기서 확정하지 않는다.

## Project selection과 section lifetime

`ProjectSidebarScreen`은 folder-like Project row를 `ProjectID`로 표시하고 직접 선택한다.

1. row selection은 `AppFeature`에 `.project(ProjectID)` route intent를 보낸다.
2. `AppFeature`는 기존 Project effect를 취소하고 새 `ProjectWorkspaceFeature`를 scope한다.
3. Workspace는 selected Todo/Memo/Chat section, authoritative `selectedTodoID`와
   editor/Inspector destination lifetime을 소유한다. scoped `TodoFeature`와 projection child는
   parent selection binding/action delegate를 소비한다.
4. drag/drop reorder는 local preference client에 `[ProjectID]`만 저장한다. 저장 실패는 row
   identity나 현재 route를 바꾸지 않으며 retry/error를 UI preference 경계에서 처리한다.
5. 재실행 때 저장된 ID 순서를 현재 접근 가능한 Project 목록에 적용한다. 사라진 ID는
   무시하고 새 Project는 결정론적인 fallback 위치에 놓는다. 이는 Domain mutation이 아니다.

Project가 Local/Hosted/Shared/Offline/Detached로 바뀌어도 `ProjectID` route는 유지된다.
access가 Detached로 바뀌면 같은 Workspace가 read-only projection과 lifecycle banner를
보여준다.

## Membership, lifecycle와 Detached route

| Entry/action | Screen owner | route/presentation 결과 | 허용 조건 |
| --- | --- | --- | --- |
| invite | `ProjectMembersFeature` | `InviteMemberSheet` | Owner의 membership capability |
| voluntary leave | Members 또는 Settings의 Project lifecycle action | leave confirmation; 수신 뒤 같은 `ProjectID`의 Detached Workspace | Member 또는 transfer가 완료된 기존 Owner |
| kick | `ProjectMembersFeature` | `KickConfirmationAlert`; 제거 client는 Detached | Owner의 membership capability, 자기 자신 제외 |
| ownership transfer request | `ProjectMembersFeature` | target Member에게 pending request 표시 | 현재 Owner |
| ownership transfer accept | target의 `ProjectMembersFeature` | acceptance 뒤에만 Owner role 변경 | 지정된 target Member |
| Owner leave before acceptance | Project lifecycle guard | `OwnerLeaveGuardAlert`; leave command를 보내지 않음 | transfer가 아직 수락되지 않은 Owner |
| Detached copy | `ProjectWorkspaceFeature` | `.detachedCopy(ProjectID)` presentation에서 새 1인 Local Project로 이동 가능 | Detached이며 현재 identity가 작성한 Todo/Memo가 있음 |

Detached copy는 명시적 사용자 action이다. 새 Local Project와 복사된 본인 Todo/Memo에는 새
ID를 발급하고, 타 작성자 content와 Chat은 복사하지 않는다. 따라서 Chat copy selector,
button, route와 Application command는 존재하지 않는다. 첫 kick/leave 수신 설명 이후에는
persistent Detached banner와 last-synced 시점을 유지하고 write/send/member mutation action을
노출하거나 실행하지 않는다.

cutoff 뒤 access는 `detachedReadOnly`, live sync와 outbox는 `notApplicable`이다. last-synced와
cutoff 결과는 historical metadata이며 현재 sync/outbox 상태로 표시하지 않는다.

Membership role과 content-author authority는 별도 input이다. Owner도 다른 작성자의
Todo/Memo/Message edit/delete action을 얻지 않는다. UI는 role 이름에서 action을 재계산하지
않고 Application의 allowed-action response를 표현한다.

## Channel metadata와 Memo conflict handoff

### Multi-Channel capability

`ProjectChatScreen`은 selected `ChatChannelID`와 다음 split capability를 표현한다.

- 모든 active Member는 Channel을 생성할 수 있다.
- Channel creator는 해당 Channel의 name/topic을 변경할 수 있다.
- Project Owner는 Channel을 archive/restore할 수 있다.
- Message edit/delete는 위 channel capability와 별개이며 작성자에게만 허용된다.
- Detached에서는 create, metadata mutation, archive/restore와 send action을 제공하지 않는다.

`ChatFeature`는 role 문자열로 action을 재계산하지 않고 `HOT6-36`/`HOT6-47`의 Application
capability를 소비한다. action의 정확한 visual 위치는 `HOT6-37`/`HOT6-52`가 정하되 위
capability split과 typed `ChatChannelID` route는 바꾸지 않는다.

### Memo Revision History

whole-document conflict는 별도 collection Memo나 새 `MemoID`로 표시하지 않는다. 선택된
Memo의 Revision History에서 revision 시점, 작성자와 conflict provenance를 표시한다. 사용자가
허용된 restore action을 실행하면 선택된 `MemoID`의 과거 bytes를 직접 덮어쓰지 않고 새
revision을 만든다. Revision History presentation과 restore 결과는 `MemoFeature`가 소유하며
구체 reconcile/authorization policy는 `HOT6-31`/`HOT6-47`, semantic surface는 `HOT6-52`가
제공한다.

## Window, Panel과 presentation lifetime

| Lifetime | semantic owner | host owner | 독립성 규칙 |
| --- | --- | --- | --- |
| Main Window | `AppFeature` route와 child Feature tree | `TodoMate.app` Scene/Window | main Project route가 Panel dismiss 때문에 바뀌지 않음 |
| Workspace Todo editor | `ProjectWorkspaceFeature` destination + `TodoFeature` editor content | main window의 SwiftUI presentation host | Inspector와 연결되지만 global Panel과 별개 |
| Todo Inspector | `ProjectWorkspaceFeature` destination + `TodoFeature` content | native inspector / host-bounds drawer / explicit sheet-detail presenter | 같은 `TodoID`; show/hide가 `NSWindow` frame을 바꾸지 않음 |
| Command Palette | `CommandPaletteFeature` presentation/search/quick-capture state | retained nonactivating `NSPanel`, shortcut/focus bridge | main window 없이 열 수 있고 main Workspace presentation을 dismiss하지 않음 |
| Quick Capture | `CommandPaletteFeature`의 nested capture mode/draft | Command Palette와 같은 Panel instance | Todo editor UI를 재사용해도 Workspace Store를 공유하지 않음 |
| Menu Bar Extra | `MenuBarFeature` summary/action | `MenuBarExtra` | main/Panel을 typed delegate intent로만 열거나 route함 |

Command Palette/Quick Capture의 상세 keyboard, focus, dirty-dismiss와 Panel policy는
[Command Palette migration contract](command-palette-migration-contract.md)와 `HOT6-23`이
소유한다. `HOT6-8`은 두 mode가 하나의 독립 Panel lifetime이고 Workspace editor와는 다른
lifetime이라는 경계만 소비한다.

## Current source → target owner map

현재 구현은 target 이름을 아직 제공하지 않는다. 다음 표는 이동·교체 입력이며 완료 목록이
아니다.

| Current source/type | 현재 확인된 역할/제약 | Target owner와 migration |
| --- | --- | --- |
| `TodoMate/Application/TodoMateApp.swift`, `TodoMate/Features/Main/MainView.swift` | app-lifetime `TodoBoardStore`/`MemoStore`, global category split view와 Session listening을 조립 | `TodoMate.app` host + `AppShellScreen`/`AppFeature`; `HOT6-9`/`HOT6-28` |
| `TodoMate/Application/Navigation/NavigationDestination.swift`, `TodoMate/Application/Navigation/NavigationManager.swift` | `.todo/.memo/.group/.trash/.settings` String-like category route, global `HomeMode` | typed Project route와 scoped `ProjectWorkspaceFeature`; `HOT6-9`/`HOT6-10` |
| `TodoMate/Features/Main/Sidebar.swift` | profile이 global Settings로 연결되고 Private Todo/Memo/Trash + cached single Group를 표시; ProjectID list/reorder 없음 | `ProjectSidebarScreen`/`ProjectListFeature`, direct Project selection/local order와 Identity profile delegate; `HOT6-15`/`HOT6-28` |
| `TodoMate/Features/Home/HomeView.swift`, `TodoMate/Features/Home/Board/BoardView.swift`, `TodoMate/Features/Home/Board/BoardTodoCard.swift` | Board/Calendar global mode, View와 card가 environment Store/overlay에서 mutation | `ProjectTodoScreen` + render-only `KanbanView`; `HOT6-10`/`HOT6-29` |
| `TodoMate/Features/Home/Calendar/CalendarView.swift`, `TodoMate/Features/Home/Calendar/CalendarTodoCard.swift`, `TodoMate/Models/TodoCalendarViewModel.swift` | View별 observation, `selectedTodoId: String?`가 공용 selection이 아니며 start 때 초기화 | 같은 `ProjectWorkspaceFeature.selectedTodoID` binding을 받는 `TodoCalendarFeature`/`TodoCalendarView`; `HOT6-10`/`HOT6-30` |
| `TodoMate/Models/TodoBoardStore.swift`, `TodoMate/Models/MemoStore.swift` | app target `@Observable` canonical copy와 observation/effect | typed Application client + Feature projection/effect; `HOT6-9` 이후 점진 교체 |
| `TodoMate/Features/Memo/MemoView.swift`, `TodoMate/Features/Memo/MemoGridItem.swift`, `TodoMate/Features/Memo/MemoDetail.swift` | 전체 `Memo` + Bool을 View-local selection으로 보관하고 화면을 교체 | `ProjectMemoScreen(ProjectID)`의 `MemoID?`, collection/editor와 Revision History; `HOT6-10`/`HOT6-31`/`HOT6-47` |
| `TodoMate/Features/Group/GroupFeedWrapperView.swift`, `TodoMate/Features/Group/GroupFeed/GroupFeedView.swift`, `TodoMate/Features/Group/GroupFeed/ChatPanel.swift`, `TodoMate/Models/GroupFeedViewModel.swift`, `TodoMate/Models/SessionStore.swift`, `TodoMate/Models/TodoStore.swift`, `TodoMate/Models/MessageStore.swift` | group 하나, member Todo feed와 single chat panel, String member/group identity | 독립 `ProjectChatScreen`, 다중 `ChatChannelID`와 split Channel capability, Members/Settings flow; `HOT6-10`/`HOT6-15`/`HOT6-36`/`HOT6-37` |
| `TodoMate/Features/Overlay/TodoSheet/TodoSheet.swift`, `TodoMate/Features/Overlay/DayTodoList/DayTodoList.swift` | in-app Todo edit/day presentation | Project-scoped `TodoEditorPresentation`과 Calendar child presentation; global Panel과 분리 |
| `TodoMate/Application/WindowManager/WindowManager.swift`, `TodoMate/Application/WindowManager/ViewController/OverlayViewController.swift`, `TodoMate/Application/WindowManager/ViewController/OverlayWindowRootView.swift` | retained borderless `NSWindow`, app activate/hide, app-wide Todo Store 공유 | independent `CommandPaletteFeature` + nonactivating Panel host; `HOT6-20`/`HOT6-23` |
| `TodoMate/Features/MenuBar/MenuBarView.swift` | Project scope 없는 today Todo와 direct Store mutation | Project-aware `MenuBarFeature` + typed client/delegate; exact default scope는 이 문서가 정하지 않음 |
| `TodoMate/AppIntent/Intent/AddTodoIntent.swift`, `TodoMate/AppIntent/Intent/AddMemoIntent.swift`, `TodoMate/AppIntent/Intent/ReadTodosIntent.swift`, `TodoMate/AppIntent/Intent/UpdateTodoIntent.swift` | Project parameter 없는 legacy repository/use-case call | host-owned AppIntent adapter가 typed Project Application client를 호출; target Project 선택 정책은 별도 owner가 명시 |
| `TodoMateWidget/TodoMateWidget.swift` | read-only GRDB reader지만 `WidgetTodo.id: String`, Project scope 없는 today query | read-only Project-aware projection consumer; target Project scope policy는 이 문서가 고정하지 않음 |
| `TodoMate/Features/Trash/TrashView.swift`, `.trash` destination | legacy global Todo/Memo recovery route | canonical top-level route가 아니다. Project-scoped recovery surface 필요 여부는 owning feature issue가 정하기 전 새 route로 고정하지 않음 |
| `Common/Sources/Common/UserDefaults+.swift` | sidebar visibility와 cached single-group/profile String key | typed local Project UI preference client의 migration input; order/last selection 저장은 Domain mutation과 분리 |
| `Common/Sources/Common/AppSceneID.swift` | main window String scene ID 한 개 | Scene ID는 host lookup에만 사용하고 Product route ID로 재사용하지 않음 |
| `TodoMateUITests/ScreenType.swift`, `TodoMateUITests/ScreenNavigator.swift` | legacy screen enum/raw identifier; navigation failure를 print하고, source ID drift와 없는 dynamic group selector가 있음 | shared UI contracts + PageScreen/Component Objects로 교체; `HOT6-17`/`HOT6-12`/`HOT6-14` |
| `TodoMateUITests/Screenshot/ScreenshotTests.swift` | fixed sleep 뒤 window capture, journey/navigation과 recorder가 결합 | state-based PageScreen readiness와 독립 `ScreenshotRecorder`; `HOT6-16` |

Widget, MenuBar와 AppIntent는 Main Screen 밖의 consumer지만 Project aggregate invariant를
우회하지 않는다. 기본/current/all Project scope를 표시 문자열이나 implicit single group으로
추론하지 말고 owning issue가 typed policy로 정해야 한다. 이 문서는 external surface의
current/all/default Project scope를 정하지 않는다.

## TCA handoff

`HOT6-9`와 `HOT6-10`은 이 catalog의 Screen/Feature 이름을 시작점으로 삼는다.

- `AppFeature`는 `IdentityFeature`, `ProjectListFeature`, optional
  `ProjectWorkspaceFeature`와 `MenuBarFeature`를 조합한다. Command Palette는 optional seam으로
  먼저 연결하고 `HOT6-23`이 구체 lifecycle을 제공한다.
- `AppFeature`는 one authoritative selected `ProjectID?`를 소유한다. `ProjectListFeature`는
  selection binding/delegate와 local reorder state만 받아 selected Project copy를 만들지 않는다.
- `ProjectWorkspaceFeature`는 scoped `ProjectID`, selected section, one authoritative
  `selectedTodoID`, five semantic Project inputs와 child destination lifetime을 소유한다.
- `TodoFeature`, `KanbanFeature`, `TodoCalendarFeature`, `TodoTimelineFeature`는 parent
  selection binding/action delegate를 소비하며 별도 `TodoID?`나 entity copy를 만들지 않는다.
  projection child는 transient state/effect를 우선 소유하고 실제 구현에서 순수 render만 남는
  경우에만 `TodoFeature`로 fold한다.
- `MemoFeature`는 `selectedMemoID`, `ChatFeature`는 `selectedChatChannelID`를 소유한다.
- Project/Channel effect cancellation ID에는 안정적인 typed ID를 사용한다. 표시 이름,
  array index 또는 Relay URL을 사용하지 않는다.
- dependency는 Project/Todo/Memo/Chat/Membership typed Application client다. Presentation은
  concrete GRDB, Relay, E2EE와 Keychain adapter를 import하지 않는다.
- TestStore는 success/failure/cancel/delay/stale/unauthorized/Detached transition을 다루지만
  PageScreen 사용자 journey를 대신하지 않는다.

## AccessibilityID와 POM handoff

`HOT6-17`은 app과 UI test가 함께 import하는 lightweight `TodoMateUITestContracts`에
`AccessibilityID`, `UITestScenarioID`와 `ScreenshotID`를 구현한다. 이 문서가 고정하는 것은
semantic slot과 catalog 이름이며 raw identifier 문자열은 `HOT6-17`의 parity/duplicate gate가
소유한다.

필수 semantic slot은 다음과 같다.

- 각 PageScreen의 stable root와 loading/readiness state
- Sidebar Project row keyed by `ProjectID`, identity-profile entry, section controls와 active
  Workspace root
- Todo projection control, Todo card/event/history row keyed by `TodoID`, Inspector/editor root와
  동일 TodoID를 보존하는 presentation root
- sync와 outbox의 서로 다른 status/detail slot, Detached access reason/last-synced slot
- Memo row keyed by `MemoID`, Memo editor와 Revision History root, stable revision identity,
  conflict provenance와 restore-as-new-revision action
- Channel row keyed by `ChatChannelID`, conversation/composer root, message row keyed by
  `MessageID`, create/creator name-topic/Owner archive-restore capability action
- Members/Settings의 invite, leave, kick, transfer request/accept와 Owner leave guard
- Detached banner, last-synced value와 own Todo/Memo copy action; Chat copy slot은 없음
- Identity recovery file/QR surface와 Project encryption summary의 서로 다른 roots
- Command Palette panel, search/quick-capture mode, focus target와 result identity

동적 identifier는 stable opaque ID에서만 만든다. Project 이름, Todo/Memo/Message content,
localized label, user email, Relay URL, identity key와 Project key material은 identifier에 넣지
않는다.

POM은 다음 규칙을 따른다.

- `AppShellPageScreen.selectProject(ProjectID)`는 도착을 확인한
  `ProjectWorkspacePageScreen`을 반환한다.
- `ProjectSidebarComponent.openIdentityProfile()`은 global Identity route를 요청하고 도착을
  확인한 `IdentityRecoveryPageScreen`을 반환한다. 이 route는 selected Project를 바꾸지 않는다.
- Workspace의 Todo/Memo/Chat 전환은 각각 도착을 확인한 canonical PageScreen을 반환한다.
- Kanban/Calendar/Timeline, Sidebar, ChannelList, Conversation과 Composer는 PageScreen이
  조합하는 Component Object다.
- `ProjectTodoPageScreen`은 wide/medium/narrow fixture에서 같은 TodoID의 Inspector 도착을
  확인하고, show/hide 전후 app window frame이 바뀌지 않았음을 검증할 수 있는 transition을
  제공한다.
- `ProjectMemoPageScreen.openRevisionHistory()`는 선택 Memo의 revision-history component를
  반환한다. conflict version restore는 새 revision이 보이는 결과로 assert하고 별도 Memo row
  생성으로 assert하지 않는다.
- `ProjectChatPageScreen`은 Channel create, creator name/topic update와 Owner archive/restore를
  typed capability fixture로 검증하고 권한 없는 actor/Detached에는 해당 action이 없거나
  disabled reason과 함께 비활성화됐음을 assert한다.
- PageScreen은 selector lookup, state-based wait, user action, visible-result assertion과
  transition을 소유한다. test body는 journey만 읽히게 작성한다.
- 각 PageScreen은 `assertLoaded()`와 async work/animation이 끝난 `assertStable()`을 제공한다.
  raw query, localized label query와 고정 `sleep`을 test body에 두지 않는다.
- 탐색 실패는 print-and-continue가 아니라 assertion failure다. 화면 도착은 다음 화면의
  stable root로 검증한다.
- screenshot capture/naming은 PageScreen 바깥의 `ScreenshotRecorder`와 catalog가 소유한다.
  POM journey pass와 screenshot baseline은 서로의 증거를 대신하지 않는다.
- POM은 TCA State, GRDB row, Relay fixture나 secret을 직접 읽지 않고 사용자에게 보이는
  결과만 assertion한다.

현재 `ScreenType`/`ScreenNavigator`는 이 POM의 기반 구현이 아니다. 예를 들어
`personalBoardView`/`privateBoardView`, `settingView`/`setting_view` drift와 source에 없는
`sidebar_group_<id>` lookup이 있으므로 shared contract 도입 때 fail-closed하게 교체한다.

## Issue ownership과 순서

| Owner issue | 이 문서에서 받는 계약 |
| --- | --- |
| `HOT6-26` | opaque Project/Todo/Memo/ChatChannel ID와 typed Project/Todo/Memo client bootstrap |
| `HOT6-9` | Presentation package, AppFeature root, Screen/store와 render View 경계 |
| `HOT6-10` | Workspace-owned TodoID, projection child hierarchy, R3 destination과 effect cancellation |
| `HOT6-15` | Identity/Members/Settings와 invite/leave/kick/transfer/guard presentations |
| `HOT6-17` | shared AccessibilityID/scenario/screenshot contracts와 dynamic ID parity |
| `HOT6-20`/`HOT6-23`/`HOT6-43` | one independent Panel, AppKit lifecycle, typed search route와 Quick Capture |
| `HOT6-28` | Project Sidebar direct selection/reorder persistence와 Workspace shell |
| `HOT6-29`/`HOT6-30` | Kanban/Calendar/Timeline implementation using one Workspace TodoID binding |
| `HOT6-31`/`HOT6-47`/`HOT6-52` | Memo collection/editor, conflict Revision History와 restore-as-new-revision |
| `HOT6-36`/`HOT6-37`/`HOT6-47`/`HOT6-52` | multi-Channel Chat과 create/creator-edit/Owner archive-restore capability |
| `HOT6-50`/`HOT6-51` | R3 native inspector/drawer/sheet-detail implementation과 semantic surface |
| `HOT6-12`/`HOT6-14` | Selector/PageScreen foundation과 Project Workspace journeys |
| `HOT6-16`/`HOT6-44` | screenshot catalog와 Command Palette journey/screenshot |
| `HOT6-51`/`HOT6-52` | semantic visual surfaces; R4 final token 전까지 reversible fixture |

이 문서는 package 생성, Swift type 추가, Xcode target 변경, R2/R4 final visual 선택, R3
container 구현이나 POM 구현을 소유하지 않는다.

## 검증 기준

문서 변경은 다음으로 검증한다.

```bash
git diff --check
git diff -- docs/app-architecture.md docs/screen-view-route-catalog.md
```

추가로 이 문서가 참조하는 repository path와 relative Markdown link가 존재하는지 확인하고,
canonical/Linear의 Screen–View, TCA와 POM 명칭을 대조한다. 문서-only 변경이므로 app build나
runtime/POM pass를 주장하지 않는다.
