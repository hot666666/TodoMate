---
trigger: always_on
---

# Domain-Driven Development Guide

This project follows **Clean Architecture** with a focus on a **pure Swift Domain layer**. When adding new features (not just UI modifications), follow this development workflow to maintain consistency, testability, and a clean separation of concerns.

If you are working on feature development rather than UI or minor functional modifications, the following development approach may be helpful.



---

## Development Workflow for New Features

### 1. Define Entity (Domain Layer)
Start by identifying and modeling the core business concepts.

```swift
// Domain/Entity/Memo.swift
struct Memo: Identifiable, Codable, Equatable {
  let id: String
  var content: String
  let createdAt: Date
  var updatedAt: Date
  let owner: String
}
```

**Key Principles:**
- Entities are **pure Swift** structs/classes with no framework dependencies
- They represent core business concepts and rules
- Keep them persistence-ignorant (no Firestore/CoreData annotations)

---

### 2. Define UseCase Protocol (Domain Layer)
Define what the feature **does** through protocol-based interfaces.

```swift
// Domain/UseCase/Memo/CreateMemoUseCase.swift
protocol CreateMemoUseCase {
  func run(for userId: String, _ memo: Memo) throws
}
```

**Benefits:**
- Abstracts business logic from implementation details
- Enables easy mocking for tests
- Single Responsibility: one UseCase = one business action

---

### 3. Define Repository Protocol (Domain Layer)
Abstract data access through repository interfaces.

```swift
// Domain/UseCase/Protocols/MemoRepository.swift
protocol MemoRepository {
  func create(for userId: String, _ memo: Memo) async throws
  func readAll(for userId: String) async throws -> [Memo]
  func update(for userId: String, _ memo: Memo) async throws
  func delete(for userId: String, _ memo: Memo) async throws
}
```

**Key Insight:**
- Repository protocols live in the **Domain layer**
- Implementations (Firebase, SwiftData, etc.) live in the **Data layer**
- This inversion of dependencies keeps the domain pure

---

### 4. Implement Repository (Data Layer)
Create concrete implementations for data persistence.

```swift
// Data/MemoRepositoryImpl.swift
struct MemoRepositoryImpl: MemoRepository {
  private let db = Firestore.firestore()

  func create(for userId: String, _ memo: Memo) async throws {
    try db.collection("users").document(userId)
      .collection("memos").document(memo.id)
      .setData(from: memo)
  }
  // ... other implementations
}
```

---

### 5. Implement UseCase (Domain Layer)
Orchestrate business logic using repository abstractions.

```swift
// Domain/UseCase/Memo/CreateMemoUseCaseImpl.swift
struct CreateMemoUseCaseImpl: CreateMemoUseCase {
  let repository: MemoRepository

  func run(for userId: String, _ memo: Memo) throws {
    Task {
      try await repository.create(for: userId, memo)
    }
  }
}
```

---

### 6. Register in DIContainer
Wire up dependencies for injection.

```swift
// Application/Dependency/DIContainer.swift
let createMemoUseCase: CreateMemoUseCase

init() {
  let memoRepo = MemoRepositoryImpl()
  createMemoUseCase = CreateMemoUseCaseImpl(repository: memoRepo)
}
```

---

### 7. Use in Store/View (Presentation Layer)
Consume use cases through observable stores.

```swift
// Models/MemoStore.swift
@Observable @MainActor
final class MemoStore {
  private let createMemoUseCase: CreateMemoUseCase

  func add(_ memo: Memo, userId: String) {
    try? createMemoUseCase.run(for: userId, memo)
    // Optimistic update
    memos[userId, default: []].append(memo)
  }
}
```

---

## Testing Strategy

Each layer can be tested independently:

| Layer | What to Test | How to Mock |
|-------|--------------|-------------|
| **Entity** | Business rules, validation | N/A (pure logic) |
| **UseCase** | Orchestration logic | Mock Repository |
| **Repository** | Data operations | Firebase Emulator / In-memory |
| **Store** | State management | Mock UseCases |
| **View** | UI behavior | Mock Store + Preview |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│  Presentation (SwiftUI App)                             │
│  ├─ Views        → UI components                        │
│  └─ Stores       → @Observable state containers         │
├─────────────────────────────────────────────────────────┤
│  Domain (Pure Swift)                                    │
│  ├─ Entity/      → Business models (User, Todo, Memo)   │
│  ├─ UseCase/     → Business logic (protocols + impls)   │
│  └─ Protocols/   → Repository interfaces                │
├─────────────────────────────────────────────────────────┤
│  Data (Framework-dependent)                             │
│  └─ *RepositoryImpl → Firebase/SwiftData implementations│
└─────────────────────────────────────────────────────────┘

* Dependencies flow INWARD: Presentation → Domain ← Data
```

---

## Key Benefits

| Benefit | Description |
|---------|-------------|
| **Testability** | Each layer is independently testable with mock dependencies |
| **Maintainability** | Changes in one layer don't ripple to others |
| **Flexibility** | Easy to swap implementations (e.g., Firebase → SwiftData) |
| **Consistency** | Uniform development process for all features |
| **Onboarding** | Clear structure helps new developers understand the codebase |

---

## Quick Reference: Adding a New Feature

```
1. Entity          → Define business model in Domain/Entity/
2. Repository      → Define protocol in Domain/UseCase/Protocols/
3. UseCase         → Define protocol + impl in Domain/UseCase/[Feature]/
4. RepositoryImpl  → Implement in Data/
5. DIContainer     → Register dependencies
6. Store           → Add methods using UseCases
7. View            → Build UI consuming Store
8. Tests           → Write tests at each layer
```

---
