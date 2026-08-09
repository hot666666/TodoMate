# Agent Guide for TodoMate

This file provides guidance to the agent when working with code in this repository.

## Project Overview

TodoMate is a native macOS todo application built entirely in SwiftUI following Clean Architecture principles.
It supports personal todos with SwiftData, group collaboration features including shared feeds and chat, and syncs data through Firebase.

**Target Platform**: macOS 26+

## Build Commands

All commands use `just` (command runner). Logs are saved to `.test-logs/`.

```bash
# Build
just build

# Tests (by layer)
just test-domain          # Domain layer unit tests (swift test)
just test-data            # Data layer unit tests (swift test)
just test-data-integration # Data layer Firebase tests (requires emulator)
just test-app             # App unit tests (xcodebuild)
just test-app-runtime     # App runtime/UI tests (requires emulator)
just test-all             # Run all tests in order

# Screenshots
just ui-screenshots       # Capture all screens
SCREENS=personal_board,memo just ui-screenshots  # Specific screens

# Utilities
just clean-logs           # Clear test logs
just start-emulator       # Start Firebase emulator
just stop-emulator        # Stop Firebase emulator
```

## Architecture

### Modular Package Structure

```
TodoMate/                    # Xcode project (Presentation layer)
├── Application/             # App entry, DI, Navigation
├── Features/                # SwiftUI Views per feature
└── Models/                  # @Observable stores

TodoMateDomain/              # SPM package (Domain layer)
├── Entity/                  # Business models (User, Todo, Memo, etc.)
└── UseCase/                 # Business logic protocols & implementations

TodoMateData/                # SPM package (Data layer)
├── *Impl.swift              # Firebase/SwiftData implementations
├── Configuration/           # Firebase/emulator setup
└── Errors/                  # Domain-specific error types

Common/                      # SPM package (Shared utilities)
└── Logger, Extensions, etc.
```

### Key Architectural Patterns

- **Clean Architecture**: Domain layer is pure Swift with no framework dependencies
- **Protocol-based DI**: All dependencies managed through `DIContainer`
- **@Observable Stores**: App-wide state via `Store`
- **Swift Concurrency**: `async/await` throughout, strict concurrency compliance

### Dependency Injection

`DIContainer` (in `Application/Dependency/`) wires up all dependencies:

```swift
// Access in views/stores
@Environment(DIContainer.self) private var container
```

### Adding New Features

1. **Entity** → Define in `TodoMateDomain/Sources/Entity/`
2. **Repository Protocol** → Define in `TodoMateDomain/Sources/UseCase/Protocols/`
3. **UseCase** → Protocol + implementation in `TodoMateDomain/Sources/UseCase/`
4. **RepositoryImpl** → Implement in `TodoMateData/Sources/`
5. **DIContainer** → Register the dependency
6. **Store/View** → Use via `DIContainer`

### Build Verification

Always verify builds after code changes:

```bash
just build
```

## Skills

Specialized agent skills are available in `.agent/skills/`:

| Skill                       | Purpose                                  |
| --------------------------- | ---------------------------------------- |
| `swift-concurrency-expert`  | Review/fix Swift 6.2+ concurrency issues |
| `swiftui-liquid-glass`      | Implement iOS 26+ Liquid Glass UI        |
| `swiftui-performance-audit` | Diagnose SwiftUI performance issues      |
| `swiftui-ui-patterns`       | Best practices for SwiftUI components    |
| `swiftui-view-refactor`     | Refactor views for consistency           |
| `gh-issue-fix-flow`         | End-to-end GitHub issue fix workflow     |
| `app-store-changelog`       | Generate release notes from git history  |
| `pre-commit-hooks`          | Run pre-commit hooks                     |

Read skill instructions with `view_file` on `SKILL.md` before use.

## Workflows

Agent workflows are in `.agent/workflows/`:

- `/development-workflow` - TDD-based development process
- `/commit` - Commit with proper conventional messages
- `/gh-create-pr` - Create GitHub PR

## Documentation

Reference docs in `docs/`:

- [Liquid Glass Guide](docs/liquid-glass-guide.md) - iOS 26+ design system
- [Swift Concurrency](docs/mediator-with-swift-concurreny.md) - Modern async patterns
- [Swift Testing](docs/swift-testing-guide.md) - Testing framework guide
- [XCTest UI Testing](docs/xctest-ui-test.md) - UI testing patterns

Additional rules in `.agent/rules/`:

- `project-rules.md` - Swift/SwiftUI coding standards
- `git-conventions.md` - Commit message and merge guidelines
- `DDD.md` - Domain-driven development guide

## UI Screens

Available for screenshot testing:

| Screen            | File                    |
| ----------------- | ----------------------- |
| Personal Board    | `personal_board.png`    |
| Personal Calendar | `personal_calendar.png` |
| Memo              | `memo.png`              |
| Group Feed        | `group_feed.png`        |
| No Groups         | `no_groups.png`         |
| Settings          | `settings.png`          |
