---
schemaVersion: 1
documentId: current.modules
modelLayer: modules
verifiedGitCommit: 81f29883bbda166d7387a0090abe6e34ff69bc32
status: current
---

# Build Units and Modules

# Nodes

## repo.todomate

- kind: repository
- summary: macOS application repository with one Xcode project and four local Swift packages.
- parent: -
- module: repository
- status: observed
- confidence: high
- source: TodoMate.xcodeproj/project.pbxproj#rootObject = 45E10B872C69B77300FC31CD

## package.common

- kind: build-unit
- summary: Local Swift package that produces the Common utility module.
- parent: repo.todomate
- module: Common package
- status: observed
- confidence: high
- source: Common/Package.swift#name: "Common"

## module.common

- kind: module
- summary: Foundation and OSLog-oriented utilities shared by current packages and the app host.
- parent: package.common
- module: Common
- status: observed
- confidence: high
- source: Common/Package.swift#.target(

## package.domain

- kind: build-unit
- summary: Local Swift package currently named TodoMateDomain and producing Domain plus Application modules.
- parent: repo.todomate
- module: TodoMateDomain package
- status: observed
- confidence: high
- source: TodoMateDomain/Package.swift#name: "TodoMateDomain"

## module.domain

- kind: module
- summary: Domain entities, repository protocols, policies, and legacy use cases.
- parent: package.domain
- module: TodoMateDomain
- status: observed
- confidence: high
- source: TodoMateDomain/Package.swift#name: "TodoMateDomain",

## module.application

- kind: module
- summary: Typed application client surface currently containing ProjectClient and ProjectPersistence.
- parent: package.domain
- module: TodoMateApplication
- status: observed
- confidence: high
- source: TodoMateDomain/Package.swift#name: "TodoMateApplication",

## package.data

- kind: build-unit
- summary: Local Swift package that owns GRDB and current external/local adapter implementations.
- parent: repo.todomate
- module: TodoMateData package
- status: observed
- confidence: high
- source: TodoMateData/Package.swift#name: "TodoMateData"

## module.data

- kind: module
- summary: GRDB database, records, migrations, repositories, and legacy adapters.
- parent: package.data
- module: TodoMateData
- status: observed
- confidence: high
- source: TodoMateData/Package.swift#name: "TodoMateData",

## executable.grdb-readonly-probe

- kind: build-unit
- summary: Command-line probe for the narrow GRDB read-only projection path.
- parent: package.data
- module: GRDBReadOnlyProjectionProbe
- status: observed
- confidence: high
- source: TodoMateData/Package.swift#name: "GRDBReadOnlyProjectionProbe",

## package.presentation

- kind: build-unit
- summary: Local Swift package for the Project-first TCA slice and shared UI-test identifiers.
- parent: repo.todomate
- module: TodoMatePresentation package
- status: observed
- confidence: high
- source: TodoMatePresentation/Package.swift#name: "TodoMatePresentation"

## module.presentation

- kind: module
- summary: SwiftUI screens and TCA reducers for the current Project-first app path.
- parent: package.presentation
- module: TodoMatePresentation
- status: observed
- confidence: high
- source: TodoMatePresentation/Package.swift#.library(name: "TodoMatePresentation"

## module.uitest-contracts

- kind: module
- summary: Shared AccessibilityID contract linked by Presentation and the native UI-test target.
- parent: package.presentation
- module: TodoMateUITestContracts
- status: observed
- confidence: high
- source: TodoMatePresentation/Package.swift#.library(name: "TodoMateUITestContracts"

## target.app

- kind: build-unit
- summary: Native macOS application target and composition root.
- parent: repo.todomate
- module: TodoMate.app
- status: observed
- confidence: high
- source: TodoMate.xcodeproj/project.pbxproj#name = TodoMate;

## target.app-tests

- kind: build-unit
- summary: Native unit-test bundle depending on the application target.
- parent: repo.todomate
- module: TodoMateTests
- status: observed
- confidence: high
- source: TodoMate.xcodeproj/project.pbxproj#name = TodoMateTests;

## target.ui-tests

- kind: build-unit
- summary: Native UI-test bundle linking the UI-test contract product and targeting TodoMate.app.
- parent: repo.todomate
- module: TodoMateUITests
- status: observed
- confidence: high
- source: TodoMate.xcodeproj/project.pbxproj#name = TodoMateUITests;

## folder.app-source

- kind: source-folder
- summary: Filesystem source folder for the native application host and remaining legacy UI.
- parent: target.app
- module: TodoMate source folder
- status: observed
- confidence: high
- source: TodoMate/Application/TodoMateApp.swift#struct TodoMateApp: App

## ide-group.app-source

- kind: ide-group
- summary: Xcode file-system-synchronized group named TodoMate; it is not itself a module or target.
- parent: target.app
- module: TodoMate Xcode group
- status: observed
- confidence: high
- source: TodoMate.xcodeproj/project.pbxproj#45DA69ED2E238B00007183E3 /* TodoMate */

# Relationships

| sourceId | kind | targetId | status | confidence | evidence |
| --- | --- | --- | --- | --- | --- |
| package.common | produces | module.common | observed | high | Common/Package.swift#targets: [ |
| package.domain | produces | module.domain | observed | high | TodoMateDomain/Package.swift#targets: [ |
| package.domain | produces | module.application | observed | high | TodoMateDomain/Package.swift#name: "TodoMateApplication", |
| package.data | produces | module.data | observed | high | TodoMateData/Package.swift#name: "TodoMateData", |
| package.data | produces | executable.grdb-readonly-probe | observed | high | TodoMateData/Package.swift#.executableTarget( |
| package.presentation | produces | module.presentation | observed | high | TodoMatePresentation/Package.swift#.target( |
| package.presentation | produces | module.uitest-contracts | observed | high | TodoMatePresentation/Package.swift#.target(name: "TodoMateUITestContracts") |
| target.app | compiles-source | folder.app-source | observed | high | TodoMate.xcodeproj/project.pbxproj#45DA69ED2E238B00007183E3 /* TodoMate */ |
| target.app | displays-as | ide-group.app-source | observed | high | TodoMate.xcodeproj/project.pbxproj#fileSystemSynchronizedGroups = ( |

# Hierarchy

| parentId | childId | relationship | condition | evidence |
| --- | --- | --- | --- | --- |
| repo.todomate | package.common | contains-build-unit | always | Common/Package.swift#let package = Package( |
| repo.todomate | package.domain | contains-build-unit | always | TodoMateDomain/Package.swift#let package = Package( |
| repo.todomate | package.data | contains-build-unit | always | TodoMateData/Package.swift#let package = Package( |
| repo.todomate | package.presentation | contains-build-unit | always | TodoMatePresentation/Package.swift#let package = Package( |
| repo.todomate | target.app | contains-build-unit | always | TodoMate.xcodeproj/project.pbxproj#PBXNativeTarget section |
| repo.todomate | target.app-tests | contains-build-unit | always | TodoMate.xcodeproj/project.pbxproj#name = TodoMateTests; |
| repo.todomate | target.ui-tests | contains-build-unit | always | TodoMate.xcodeproj/project.pbxproj#name = TodoMateUITests; |

# Traces

# Unresolved

| elementId | reason | verificationSuggestion | evidence |
| --- | --- | --- | --- |
