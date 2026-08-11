---
schemaVersion: 1
documentId: current.ui-hierarchy
modelLayer: ui
verifiedGitCommit: 81f29883bbda166d7387a0090abe6e34ff69bc32
status: current
---

# View Composition and Navigation

# Nodes

## ui.todomate-app

- kind: screen
- summary: SwiftUI App root that owns the Menu Bar scene, main Window scene, and host dependency lifetime.
- parent: layer.host
- module: TodoMate.app
- status: observed
- confidence: high
- source: TodoMate/Application/TodoMateApp.swift#struct TodoMateApp: App

## ui.menu-bar

- kind: view
- summary: Parallel MenuBarExtra surface receiving TodoBoardStore from the host.
- parent: ui.todomate-app
- module: TodoMate.app
- status: observed
- confidence: high
- source: TodoMate/Application/TodoMateApp.swift#MenuBarExtra("TodoMate"

## ui.main-window

- kind: screen
- summary: Main macOS Window scene that composes MainView and environment dependencies.
- parent: ui.todomate-app
- module: TodoMate.app
- status: observed
- confidence: high
- source: TodoMate/Application/TodoMateApp.swift#Window("TodoMate", id: AppSceneID.mainApp.rawValue)

## ui.main-view

- kind: view
- summary: Thin native-host bridge that passes ProjectClient into the Project-first package screen.
- parent: ui.main-window
- module: TodoMate.app
- status: observed
- confidence: high
- source: TodoMate/Features/Main/MainView.swift#ProjectAppScreen(projectClient: container.core.projectClient)

## ui.project-app-screen

- kind: screen
- summary: Project-first NavigationSplitView root and TCA Store owner.
- parent: ui.main-view
- module: TodoMatePresentation
- status: observed
- confidence: high
- source: TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectAppScreen.swift#public struct ProjectAppScreen: View

## ui.project-sidebar-screen

- kind: screen
- summary: Project list, selection, create action, and create-sheet presentation.
- parent: ui.project-app-screen
- module: TodoMatePresentation
- status: observed
- confidence: high
- source: TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectSidebarScreen.swift#struct ProjectSidebarScreen: View

## ui.project-sidebar-view

- kind: view
- summary: Render-focused Projects list receiving values and narrow callbacks from its Screen.
- parent: ui.project-sidebar-screen
- module: TodoMatePresentation
- status: observed
- confidence: high
- source: TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectSidebarScreen.swift#private struct ProjectSidebarView: View

## ui.project-create-view

- kind: view
- summary: Local Project name form presented as a sheet by ProjectSidebarScreen.
- parent: ui.project-sidebar-screen
- module: TodoMatePresentation
- status: observed
- confidence: high
- source: TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectSidebarScreen.swift#private struct ProjectCreateView: View

## ui.project-workspace-screen

- kind: screen
- summary: Selected Project title, lifecycle, section picker, and current placeholder destinations.
- parent: ui.project-app-screen
- module: TodoMatePresentation
- status: observed
- confidence: high
- source: TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectWorkspaceScreen.swift#struct ProjectWorkspaceScreen: View

## ui.project-workspace-view

- kind: view
- summary: Render-focused workspace content receiving Project values and section callback.
- parent: ui.project-workspace-screen
- module: TodoMatePresentation
- status: observed
- confidence: high
- source: TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectWorkspaceScreen.swift#private struct ProjectWorkspaceView: View

## ui.project-todo-placeholder

- kind: view
- summary: Current Todo section placeholder; Project-scoped Todo content is not yet implemented in this route.
- parent: ui.project-workspace-view
- module: TodoMatePresentation
- status: observed
- confidence: high
- source: TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectWorkspaceScreen.swift#description: Text("이 Project의 Todo section입니다.")

## ui.project-memo-placeholder

- kind: view
- summary: Current Memo section placeholder in the Project-first workspace.
- parent: ui.project-workspace-view
- module: TodoMatePresentation
- status: observed
- confidence: high
- source: TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectWorkspaceScreen.swift#ContentUnavailableView("Memo"

## ui.project-chat-placeholder

- kind: view
- summary: Current Chat section placeholder in the Project-first workspace.
- parent: ui.project-workspace-view
- module: TodoMatePresentation
- status: observed
- confidence: high
- source: TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectWorkspaceScreen.swift#ContentUnavailableView("Chat"

## ui.overlay-controller

- kind: screen
- summary: AppKit overlay surface retained beside the SwiftUI Project route and registered with WindowManager.
- parent: ui.todomate-app
- module: TodoMate.app
- status: observed
- confidence: high
- source: TodoMate/Application/TodoMateApp.swift#WindowManager.shared.overlayController = overlayViewController

## ui.legacy-sidebar

- kind: view
- summary: Source-retained Private/Public navigation Sidebar; MainView no longer composes it.
- parent: layer.host
- module: TodoMate.app
- status: legacy-dormant
- confidence: high
- source: TodoMate/Features/Main/Sidebar.swift#struct Sidebar: View

## ui.legacy-home

- kind: view
- summary: Source-retained Board/Calendar Home surface not composed by the current MainView.
- parent: layer.host
- module: TodoMate.app
- status: legacy-dormant
- confidence: high
- source: TodoMate/Features/Home/HomeView.swift#struct HomeView: View

## ui.legacy-memo

- kind: view
- summary: Source-retained Memo grid/detail surface not composed by the current MainView.
- parent: layer.host
- module: TodoMate.app
- status: legacy-dormant
- confidence: high
- source: TodoMate/Features/Memo/MemoView.swift#struct MemoView: View

## ui.legacy-group

- kind: view
- summary: Source-retained Group feed wrapper using legacy Session/Todo/Message stores; not composed by current MainView.
- parent: layer.host
- module: TodoMate.app
- status: legacy-dormant
- confidence: high
- source: TodoMate/Features/Group/GroupFeedWrapperView.swift#struct GroupFeedWrapperView: View

# Relationships

| sourceId | kind | targetId | status | confidence | evidence |
| --- | --- | --- | --- | --- | --- |
| ui.main-window | presents | ui.main-view | observed | high | TodoMate/Application/TodoMateApp.swift#MainView(container: appDIContainer) |
| ui.main-view | presents | ui.project-app-screen | observed | high | TodoMate/Features/Main/MainView.swift#ProjectAppScreen(projectClient: container.core.projectClient) |
| ui.project-app-screen | presents | ui.project-sidebar-screen | observed | high | TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectAppScreen.swift#ProjectSidebarScreen( |
| ui.project-app-screen | presents | ui.project-workspace-screen | observed | high | TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectAppScreen.swift#ProjectWorkspaceScreen(store: workspaceStore) |
| ui.project-sidebar-screen | presents | ui.project-create-view | observed | high | TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectSidebarScreen.swift#.sheet(isPresented: Binding( |
| ui.project-workspace-view | switches-to | ui.project-todo-placeholder | observed | high | TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectWorkspaceScreen.swift#case .todo: |
| ui.project-workspace-view | switches-to | ui.project-memo-placeholder | observed | high | TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectWorkspaceScreen.swift#case .memo: |
| ui.project-workspace-view | switches-to | ui.project-chat-placeholder | observed | high | TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectWorkspaceScreen.swift#case .chat: |

# Hierarchy

| parentId | childId | relationship | condition | evidence |
| --- | --- | --- | --- | --- |
| ui.todomate-app | ui.menu-bar | composes-parallel-surface | always | TodoMate/Application/TodoMateApp.swift#MenuBarExtra("TodoMate" |
| ui.todomate-app | ui.main-window | composes-scene | always | TodoMate/Application/TodoMateApp.swift#Window("TodoMate" |
| ui.todomate-app | ui.overlay-controller | composes-parallel-surface | always | TodoMate/Application/TodoMateApp.swift#overlayViewController = Self.composeVCandRegisterHotKey |
| ui.main-window | ui.main-view | composes | always | TodoMate/Application/TodoMateApp.swift#MainView(container: appDIContainer) |
| ui.main-view | ui.project-app-screen | composes | always | TodoMate/Features/Main/MainView.swift#ProjectAppScreen(projectClient: container.core.projectClient) |
| ui.project-app-screen | ui.project-sidebar-screen | navigation-split-sidebar | always | TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectAppScreen.swift#NavigationSplitView { |
| ui.project-app-screen | ui.project-workspace-screen | navigation-split-detail | selected Project exists | TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectAppScreen.swift#if let workspaceStore |
| ui.project-sidebar-screen | ui.project-sidebar-view | renders | always | TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectSidebarScreen.swift#ProjectSidebarView( |
| ui.project-sidebar-screen | ui.project-create-view | presents-sheet | create state is presented | TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectSidebarScreen.swift#ProjectCreateView( |
| ui.project-workspace-screen | ui.project-workspace-view | renders | always | TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectWorkspaceScreen.swift#ProjectWorkspaceView( |
| ui.project-workspace-view | ui.project-todo-placeholder | conditionally-renders | selectedSection is todo | TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectWorkspaceScreen.swift#case .todo: |
| ui.project-workspace-view | ui.project-memo-placeholder | conditionally-renders | selectedSection is memo | TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectWorkspaceScreen.swift#case .memo: |
| ui.project-workspace-view | ui.project-chat-placeholder | conditionally-renders | selectedSection is chat | TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectWorkspaceScreen.swift#case .chat: |

# Traces

# Unresolved

| elementId | reason | verificationSuggestion | evidence |
| --- | --- | --- | --- |
| ui.legacy-sidebar | The source remains compilable but has no current producer from MainView. | Confirm removal or a future route before changing its status. | TodoMate/Features/Main/MainView.swift#ProjectAppScreen(projectClient: container.core.projectClient) |
