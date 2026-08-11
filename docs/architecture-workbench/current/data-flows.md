---
schemaVersion: 1
documentId: current.data-flows
modelLayer: flows
verifiedGitCommit: 81f29883bbda166d7387a0090abe6e34ff69bc32
status: current
---

# Evidence-backed Runtime Traces

# Nodes

# Relationships

| sourceId | kind | targetId | status | confidence | evidence |
| --- | --- | --- | --- | --- | --- |
| datastore.grdb | notifies | persistence.grdb-project | observed | high | TodoMateData/Sources/TodoMateData/GRDB/GRDBDatabase.swift#changeCenter.notifyChange(in: .project) |
| persistence.grdb-project | emits | service.project-client | observed | high | TodoMateData/Sources/TodoMateData/GRDB/Repositories/GRDBProjectPersistence.swift#public func snapshots() -> AsyncStream<ProjectWorkspaceSnapshot> |
| service.project-client | emits | state.app-feature | observed | high | TodoMatePresentation/Sources/TodoMatePresentation/Features/AppFeature.swift#case snapshotUpdated(ProjectWorkspaceSnapshot) |

# Hierarchy

| parentId | childId | relationship | condition | evidence |
| --- | --- | --- | --- | --- |

# Traces

## trace.project-launch-observation

| order | elementId | input | state change | effect/dependency | output | evidence |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | ui.project-app-screen | SwiftUI task begins | no direct canonical entity mutation | sends AppFeature ViewAction.task | task action | TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectAppScreen.swift#.task { await store.send(.view(.task)).finish() } |
| 2 | state.app-feature | ViewAction.task | starts cancellable snapshot Effect | invokes ProjectClient.snapshots | AsyncStream subscription | TodoMatePresentation/Sources/TodoMatePresentation/Features/AppFeature.swift#for await snapshot in projectClient.snapshots() |
| 3 | service.project-client | snapshots request | delegates without holding UI state | invokes ProjectPersistence snapshots closure | workspace snapshot stream | TodoMateDomain/Sources/TodoMateApplication/ProjectClient.swift#snapshots: { persistence.snapshots() } |
| 4 | persistence.grdb-project | observation subscription | fetches ordered Projects and selected ID | invokes GRDBDatabase.observe | ProjectWorkspaceSnapshot | TodoMateData/Sources/TodoMateData/GRDB/Repositories/GRDBProjectPersistence.swift#return ProjectWorkspaceSnapshot( |
| 5 | datastore.grdb | initial read or Project-region commit | de-duplicates equal snapshots | yields transformed snapshot | snapshot event | TodoMateData/Sources/TodoMateData/GRDB/GRDBDatabase.swift#guard snapshot != lastSnapshot else { continue } |
| 6 | state.app-feature | snapshotUpdated | sets launch phase, sidebar projection, and optional workspace state | scopes child reducers | render state | TodoMatePresentation/Sources/TodoMatePresentation/Features/AppFeature.swift#case let .internal(.snapshotUpdated(snapshot)): |
| 7 | ui.project-app-screen | observed TCA state | switches loading, empty, or selected Project detail | renders scoped Screens | visible Project workspace | TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectAppScreen.swift#if let workspaceStore |

## trace.create-local-project

| order | elementId | input | state change | effect/dependency | output | evidence |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | ui.project-sidebar-screen | user confirms valid Project name | Screen sends createConfirmed | invokes scoped reducer | ViewAction.createConfirmed | TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectSidebarScreen.swift#onConfirm: { store.send(.view(.createConfirmed)) } |
| 2 | state.project-sidebar-feature | createConfirmed | operation becomes creating | invokes ProjectClient.createLocal | async command | TodoMatePresentation/Sources/TodoMatePresentation/Features/ProjectSidebarFeature.swift#state.operation = .creating |
| 3 | service.project-client | CreateLocalProjectCommand | creates typed Project and owner Membership values | invokes ProjectPersistence.create selecting true | ProjectID | TodoMateDomain/Sources/TodoMateApplication/ProjectClient.swift#let ownerMembership = Membership( |
| 4 | persistence.grdb-project | Project and owner Membership | one writer transaction inserts Project, Membership, and selected Project | invokes GRDB writer | committed records | TodoMateData/Sources/TodoMateData/GRDB/Repositories/GRDBProjectPersistence.swift#try MembershipRecord(ownerMembership).insert |
| 5 | datastore.grdb | committed Project and selection regions | notifies Project observers | invokes change center | invalidation signal | TodoMateData/Sources/TodoMateData/GRDB/GRDBDatabase.swift#changeCenter.notifyChange(in: .project) |
| 6 | state.app-feature | observed updated snapshot | sidebar receives Projects and selected ID; workspace is created | no command-result entity insertion | selected Project state | TodoMatePresentation/Sources/TodoMatePresentation/Features/AppFeature.swift#state.workspace = ProjectWorkspaceFeature.State |
| 7 | ui.project-workspace-screen | scoped workspace state | renders Project name and Local lifecycle | SwiftUI observation | visible workspace | TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectWorkspaceScreen.swift#projectName: store.project.name.value |

## trace.select-project

| order | elementId | input | state change | effect/dependency | output | evidence |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | ui.project-sidebar-view | user selects a Project row | callback carries typed ProjectID | sends ProjectSidebarFeature action | projectSelected | TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectSidebarScreen.swift#onSelect: { store.send(.view(.projectSelected($0))) } |
| 2 | state.project-sidebar-feature | projectSelected | operation becomes selecting(ProjectID) | invokes ProjectClient.select | selection command | TodoMatePresentation/Sources/TodoMatePresentation/Features/ProjectSidebarFeature.swift#state.operation = .selecting(projectID) |
| 3 | service.project-client | ProjectID | delegates selection to persistence | invokes ProjectPersistence.select | completion or error | TodoMateDomain/Sources/TodoMateApplication/ProjectClient.swift#try await persistence.select(projectID) |
| 4 | persistence.grdb-project | ProjectID | verifies Project then saves current selection | invokes GRDB writer | selection record commit | TodoMateData/Sources/TodoMateData/GRDB/Repositories/GRDBProjectPersistence.swift#ProjectSelectionRecord.currentKey |
| 5 | datastore.grdb | selection commit | notifies Project region and refetches snapshot | invokes DatabaseRegionObservation | updated selectedProjectID | TodoMateData/Sources/TodoMateData/GRDB/GRDBDatabase.swift#let selectionObserver = DatabaseRegionObservation |
| 6 | state.app-feature | snapshotUpdated | replaces or refreshes optional workspace for selected Project | TCA state composition | new selected workspace | TodoMatePresentation/Sources/TodoMatePresentation/Features/AppFeature.swift#if state.workspace?.project.id == project.id |
| 7 | ui.project-app-screen | new workspace state | detail shows the selected Project | NavigationSplitView detail | visible selected Project | TodoMatePresentation/Sources/TodoMatePresentation/Screens/ProjectAppScreen.swift#ProjectWorkspaceScreen(store: workspaceStore) |

# Unresolved

| elementId | reason | verificationSuggestion | evidence |
| --- | --- | --- | --- |
