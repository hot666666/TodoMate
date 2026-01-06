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
- Test: XCTest, Swift Testing

### Target

- macOS26

## Architecture

### Layer Structure

```
┌─────────────────────────────────────────────────────────┐
│  Presentation (TodoMate/)                               │
│  ├─ Features/     → SwiftUI Views per feature           │
│  ├─ Models/       → @Observable stores (SessionStore,   │
│  │                  TodoStore, MemoStore, MessageStore) │
│  └─ Application/  → App entry, DI, Navigation           │
├─────────────────────────────────────────────────────────┤
│  Domain (Domain/)                                       │
│  ├─ Entity/       → Core business models (User, Todo..) │
│  └─ UseCase/      → Business logic protocols & impls    │
├─────────────────────────────────────────────────────────┤
│  Data (Data/)                                           │
│  └─ *RepositoryImpl.swift → Firebase/Firestore impls    │
└─────────────────────────────────────────────────────────┘
```

### Dependency Injection

All dependencies are managed through `DIContainer` (`Application/Dependency/DIContainer.swift`):

- **Repositories**: Protocol-based data access (`UserRepository`, `TodoRepository`, etc.)
- **UseCases**: Single-responsibility business logic units
- **Services**: Auth, Calendar, Network utilities
- **System**: `UserDefaults`, `NetworkController`

`DIContainer` is injected into the SwiftUI environment at app launch and accessed via `@Environment(DIContainer.self)` in stores/views.

### Observable Stores

App-wide state is managed by `@Observable` store classes in `Models/`:

| Store | Responsibility |
|-------|----------------|
| `SessionStore` | Auth state, current user, group members |
| `TodoStore` | Todo CRUD, caching, date filtering |
| `MemoStore` | Memo management |
| `MessageStore` | Group chat messages, real-time observation |

Stores receive UseCases via `DIContainer` and expose state to views.

### Adding New Features

1. **Define Entity** (`Domain/Entity/`) – Create or extend domain models if needed.
2. **Create UseCase** (`Domain/UseCase/`) – Define protocol + implementation for business logic.
3. **Update Repository** (`Data/`) – Add data access methods if new persistence is required.
4. **Register in DIContainer** – Wire up the new UseCase in the container's init.
5. **Use in Store or View** – Inject via `DIContainer` and call from `@Observable` store or directly in view methods.

**Example flow for "Delete All Completed Todos":**
```
Domain/UseCase/Todo/DeleteCompletedTodosUseCase.swift  (protocol + impl)
    ↓ uses
Data/TodoRepositoryImpl.swift  (add batch delete method)
    ↓ registered in
DIContainer.swift  (deletedCompletedTodosUseCase property)
    ↓ called from
Models/TodoStore.swift  (exposed as async method)
    ↓ triggered by
Features/Home/BoardView.swift  (button action)
```

### Navigation

Navigation is managed by `NavigationManager` (`Application/Navigation/`):

- `NavigationDestination` enum defines all navigable screens
- `NavigationManager` holds `selection`, `viewMode`, and `columnVisibility` state
- Persistence of sidebar state uses `UserDefaults` via `DIContainer`

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

| 명령어 | 설명 | 에뮬레이터 |
|--------|------|:----------:|
| `just build` | 프로젝트 빌드 | ❌ |
| `just test` | 전체 테스트 | ❌ |
| `just test-unit` | Firebase 폴더 제외 유닛 테스트 | ❌ |
| `just test-firebase` | `TodoMateTests/Firebase` 테스트만 | ✅ |
| `just test-ui` | `TodoMateUITests` 테스트만 | ✅ |
| `just test-all` | 유닛 → Firebase → UI 순서로 실행 | ✅ |

> Firebase 에뮬레이터가 필요한 테스트는 자동으로 에뮬레이터를 시작/종료합니다.

## UI Screens

현재 UI 스크린샷 테스팅이 가능한 화면 목록입니다. 새로운 화면이 추가되거나 화면 구성이 변경되면 이 목록을 업데이트해주세요.

- **Personal Board**: 개인 할 일 보드 (`personal_board.png`)
- **Personal Calendar**: 개인 할 일 캘린더 (`personal_calendar.png`)
- **Memo**: 메모 목록 (`memo.png`)
- **Group Feed**: 그룹 피드 (`group_feed.png`)
- **No Groups**: 그룹이 없는 경우의 피드 화면 (`no_groups.png`)
- **Settings**: 설정 화면 (`settings.png`)
