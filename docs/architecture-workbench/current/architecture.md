---
schemaVersion: 1
documentId: current.architecture
modelLayer: architecture
verifiedGitCommit: 81f29883bbda166d7387a0090abe6e34ff69bc32
status: current
---

# Logical Architecture

# Nodes

## layer.host

- kind: logical-layer
- summary: Native app, Scene, AppKit integration, dependency composition, Menu Bar, and overlay ownership.
- parent: target.app
- module: TodoMate.app
- status: observed
- confidence: high
- source: TodoMate/Application/TodoMateApp.swift#struct TodoMateApp: App

## layer.presentation-tca

- kind: logical-layer
- summary: Project-first SwiftUI and TCA slice; it owns Project navigation and transient UI state.
- parent: module.presentation
- module: TodoMatePresentation
- status: observed
- confidence: high
- source: TodoMatePresentation/Sources/TodoMatePresentation/Features/AppFeature.swift#public struct AppFeature: Sendable

## layer.application

- kind: logical-layer
- summary: Typed ProjectClient command and observation facade plus persistence port.
- parent: module.application
- module: TodoMateApplication
- status: observed
- confidence: high
- source: TodoMateDomain/Sources/TodoMateApplication/ProjectClient.swift#public struct ProjectClient: Sendable

## layer.domain

- kind: logical-layer
- summary: Project, Membership, typed IDs, validation, and current legacy domain surface.
- parent: module.domain
- module: TodoMateDomain
- status: observed
- confidence: high
- source: TodoMateDomain/Sources/TodoMateDomain/Entity/Project.swift#public struct Project: Equatable

## layer.data

- kind: logical-layer
- summary: GRDB schema, transaction, observation, repository, and migration adapters.
- parent: module.data
- module: TodoMateData
- status: observed
- confidence: high
- source: TodoMateData/Sources/TodoMateData/GRDB/GRDBDatabase.swift#public final class GRDBDatabase: Sendable

## component.core-di

- kind: service
- summary: MainActor observable dependency container that constructs GRDB-backed local capabilities and ProjectClient.
- parent: layer.host
- module: TodoMate.app
- status: observed
- confidence: high
- source: TodoMate/Application/Dependency/CoreDIContainer.swift#final class CoreDIContainer

## service.project-client

- kind: service
- summary: Sendable typed client for snapshots, Local Project creation, and Project selection.
- parent: layer.application
- module: TodoMateApplication
- status: observed
- confidence: high
- source: TodoMateDomain/Sources/TodoMateApplication/ProjectClient.swift#public struct ProjectClient: Sendable

## persistence.grdb-project

- kind: service
- summary: ProjectPersistence adapter that commits Project, owner Membership, and selected Project records.
- parent: layer.data
- module: TodoMateData
- status: observed
- confidence: high
- source: TodoMateData/Sources/TodoMateData/GRDB/Repositories/GRDBProjectPersistence.swift#public final class GRDBProjectPersistence

## datastore.grdb

- kind: data-store
- summary: Current canonical local database for Project workspace records and legacy Todo/Memo records.
- parent: layer.data
- module: TodoMateData
- status: observed
- confidence: high
- source: TodoMateData/Sources/TodoMateData/GRDB/GRDBMigrations.swift#static var migrator: DatabaseMigrator

## service.legacy-public-di

- kind: service
- summary: Remaining stub-backed public/group dependency container; not the Project-first data path.
- parent: layer.host
- module: TodoMate.app
- status: legacy-dormant
- confidence: high
- source: TodoMate/Application/Dependency/AppDIContainer.swift#final class AppDIContainer

# Relationships

| sourceId | kind | targetId | status | confidence | evidence |
| --- | --- | --- | --- | --- | --- |
| layer.host | composes | component.core-di | observed | high | TodoMate/Application/TodoMateApp.swift#let coreDI = createCoreDIContainer |
| component.core-di | constructs | datastore.grdb | observed | high | TodoMate/Application/Dependency/CoreDIContainer.swift#self.database = database |
| component.core-di | constructs | service.project-client | observed | high | TodoMate/Application/Dependency/CoreDIContainer.swift#projectClient = .grdb |
| layer.presentation-tca | invokes | service.project-client | observed | high | TodoMatePresentation/Sources/TodoMatePresentation/Features/AppFeature.swift#@Dependency(\.projectClient) |
| service.project-client | delegates-to | persistence.grdb-project | observed | high | TodoMateData/Sources/TodoMateData/GRDB/Repositories/GRDBProjectPersistence.swift#static func grdb( |
| persistence.grdb-project | reads-writes | datastore.grdb | observed | high | TodoMateData/Sources/TodoMateData/GRDB/Repositories/GRDBProjectPersistence.swift#database.writer.write |
| service.project-client | creates | layer.domain | observed | high | TodoMateDomain/Sources/TodoMateApplication/ProjectClient.swift#let project = try Project( |
| layer.host | retains | service.legacy-public-di | legacy-dormant | high | TodoMate/Application/TodoMateApp.swift#let publicDI = createPublicDIContainer |

# Hierarchy

| parentId | childId | relationship | condition | evidence |
| --- | --- | --- | --- | --- |
| target.app | layer.host | owns | always | TodoMate/Application/TodoMateApp.swift#struct TodoMateApp: App |
| module.presentation | layer.presentation-tca | owns | always | TodoMatePresentation/Sources/TodoMatePresentation/Features/AppFeature.swift#@Reducer |
| module.application | layer.application | owns | always | TodoMateDomain/Sources/TodoMateApplication/ProjectClient.swift#import TodoMateDomain |
| module.domain | layer.domain | owns | always | TodoMateDomain/Sources/TodoMateDomain/Entity/Project.swift#import Foundation |
| module.data | layer.data | owns | always | TodoMateData/Sources/TodoMateData/GRDB/GRDBDatabase.swift#import GRDB |

# Traces

# Unresolved

| elementId | reason | verificationSuggestion | evidence |
| --- | --- | --- | --- |
| service.legacy-public-di | Group and message stub wiring remains constructed even though MainView now renders ProjectAppScreen. | Remove or reclassify when the owning migration issue deletes the legacy runtime. | TodoMate/Application/TodoMateApp.swift#StubMessageRepository() |
