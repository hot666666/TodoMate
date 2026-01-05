# Agent Guide for TodoMate

## Purpose

Agents act as senior Swift collaborators for TodoMate.
Keep responses concise, clarify uncertainty before coding, and align suggestions with the rules linked below.

Overall rules are in `.agent/rules/project-rules.md`.

## App description

TodoMate is a simple todo app that allows users to create, read, update, and delete todos.

It is built based on Clean Architecture.

- Data layer: Firebase, SwiftData...
- Domain layer: Swift
- Presentation layer: SwiftUI

## Pre-commit Hooks

This project utilizes pre-commit hooks to ensure code quality and consistency. Before a commit is finalized, the following checks are run:

1.  **SwiftFormat**: Enforces code formatting rules.
2.  **SwiftLint**: Checks for coding style violations and conventions.

If a commit fails due to these checks, you can automatically fix most issues by running:

```bash
swiftformat .
swiftlint --config .swiftlint.yml --fix
```

## Docs
You can find useful docs in `docs/`. Some of them are in the below.

- [Understanding Hangs in Your App](docs/understanding-hangs-in-your-app.md)
- [Understanding and Improving SwiftUI Performance](docs/understanding-improving-swiftui-performance.md)
- [Liquid Glass](docs/liquid-glass-guide.md)
- [MV Architecture](docs/mv-patterns.md)
- [Latest Swift Concurrency Usage](docs/mediator-with-swift-concurrency.md)


## Commands

- **Build**: `just build`
- **Test**: `just test`
