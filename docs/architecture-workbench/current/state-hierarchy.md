---
schemaVersion: 1
documentId: current.state-hierarchy
modelLayer: state
verifiedGitCommit: 81f29883bbda166d7387a0090abe6e34ff69bc32
status: current
---

# State Ownership

# Nodes

## state.app-feature

- kind: state-owner
- summary: TCA root state for launch phase, Project sidebar, optional selected Project workspace, and snapshot Effect lifetime.
- parent: layer.presentation-tca
- module: TodoMatePresentation
- status: observed
- confidence: high
- source: TodoMatePresentation/Sources/TodoMatePresentation/Features/AppFeature.swift#public struct State: Equatable, Sendable

## state.project-sidebar-feature

- kind: state-owner
- summary: TCA owner of Project list/selection plus create-sheet draft, operation, and failure state.
- parent: state.app-feature
- module: TodoMatePresentation
- status: observed
- confidence: high
- source: TodoMatePresentation/Sources/TodoMatePresentation/Features/ProjectSidebarFeature.swift#public struct State: Equatable, Sendable

## state.project-workspace-feature

- kind: state-owner
- summary: TCA owner of the selected Project projection and transient Todo/Memo/Chat section selection.
- parent: state.app-feature
- module: TodoMatePresentation
- status: observed
- confidence: high
- source: TodoMatePresentation/Sources/TodoMatePresentation/Features/ProjectWorkspaceFeature.swift#public struct State: Equatable, Sendable

## state.todo-board-store

- kind: state-owner
- summary: MainActor Observation store for legacy local Todo observation and mutation; still injected into Menu Bar and overlay surfaces.
- parent: layer.host
- module: TodoMate.app
- status: observed
- confidence: high
- source: TodoMate/Models/TodoBoardStore.swift#final class TodoBoardStore

## state.memo-store

- kind: state-owner
- summary: MainActor Observation store for legacy local Memo observation and mutation; still constructed by the app host.
- parent: layer.host
- module: TodoMate.app
- status: observed
- confidence: high
- source: TodoMate/Models/MemoStore.swift#final class MemoStore

## state.navigation-manager

- kind: state-owner
- summary: Legacy Observation navigation selection and Home mode owner retained in source but not instantiated by current MainView.
- parent: layer.host
- module: TodoMate.app
- status: legacy-dormant
- confidence: high
- source: TodoMate/Application/Navigation/NavigationManager.swift#final class NavigationManager

# Relationships

| sourceId | kind | targetId | status | confidence | evidence |
| --- | --- | --- | --- | --- | --- |
| ui.project-app-screen | owns-store | state.app-feature | observed | high | TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectAppScreen.swift#private let store: StoreOf<AppFeature> |
| state.app-feature | scopes | state.project-sidebar-feature | observed | high | TodoMatePresentation/Sources/TodoMatePresentation/Features/AppFeature.swift#Scope(state: \.sidebar |
| state.app-feature | conditionally-scopes | state.project-workspace-feature | observed | high | TodoMatePresentation/Sources/TodoMatePresentation/Features/AppFeature.swift#.ifLet(\.workspace |
| state.app-feature | observes | service.project-client | observed | high | TodoMatePresentation/Sources/TodoMatePresentation/Features/AppFeature.swift#for await snapshot in projectClient.snapshots() |
| state.project-sidebar-feature | invokes | service.project-client | observed | high | TodoMatePresentation/Sources/TodoMatePresentation/Features/ProjectSidebarFeature.swift#try await projectClient.createLocal |
| ui.menu-bar | reads | state.todo-board-store | observed | high | TodoMate/Application/TodoMateApp.swift#.environment(todoBoardStore) |
| ui.overlay-controller | reads-writes | state.todo-board-store | observed | high | TodoMate/Application/TodoMateApp.swift#todoBoardStore: store |
| ui.main-window | retains-environment | state.memo-store | observed | high | TodoMate/Application/TodoMateApp.swift#.environment(memoStore) |

# Hierarchy

| parentId | childId | relationship | condition | evidence |
| --- | --- | --- | --- | --- |
| state.app-feature | state.project-sidebar-feature | owns-child-state | always | TodoMatePresentation/Sources/TodoMatePresentation/Features/AppFeature.swift#public var sidebar = ProjectSidebarFeature.State() |
| state.app-feature | state.project-workspace-feature | owns-child-state | selected Project exists | TodoMatePresentation/Sources/TodoMatePresentation/Features/AppFeature.swift#public var workspace: ProjectWorkspaceFeature.State? |
| layer.host | state.todo-board-store | owns-lifetime | application lifetime | TodoMate/Application/TodoMateApp.swift#@State private var todoBoardStore: TodoBoardStore |
| layer.host | state.memo-store | owns-lifetime | application lifetime | TodoMate/Application/TodoMateApp.swift#@State private var memoStore: MemoStore |

# Traces

# Unresolved

| elementId | reason | verificationSuggestion | evidence |
| --- | --- | --- | --- |
| state.memo-store | It remains host-owned although the current Project-first main route only shows a Memo placeholder. | Remove or reconnect it in the owning Memo migration slice. | TodoMate/Application/TodoMateApp.swift#@State private var memoStore: MemoStore |
