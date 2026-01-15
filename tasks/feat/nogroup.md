# Group Feature Implementation Plan

This document outlines the plan for implementing Group creation and joining features, including UI fixes and backend logic.

## 1. UI Refinement: `GroupFeedNoGroupView`
**File:** `TodoMate/Features/Group/GroupFeedNoGroupView.swift`

- **Issue:** The view clips content when window height is small.
- **Fix:**
  - Reduce internal view heights to ensure they fit within the 720px minimum window height.
  - If geometry tracking is required, use `onGeometryChange` instead.
  - Ensure the "Create" and "Join" cards are always fully visible.

## 2. Domain Layer: Define `Group` Entity
**Path:** `Domain/Entity/Group.swift`

Create a pure Swift `Group` struct.
- **Note:** `inviteCode` is removed. Joining depends on `id`.
- **Note:** `ownerId` is removed. Group ownership is collective; if the last member leaves, the group is deleted.

```swift
struct Group: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var memberIds: [String]
    let createdAt: Date
    var updatedAt: Date
}
```

## 3. Domain Layer: UseCases
**Path:** `Domain/UseCase/Group/`

### A. Create Group (`CreateGroupUseCase`)
- **Logic:**
  1. Generate a new `Group` instance (with generated ID).
  2. Call Repository to save the group.
  3. Update the current `User`'s `groupId`.
  4. (Optional) Batch write/Transaction to ensure both happen or neither.

### B. Join Group (`JoinGroupUseCase`)
- **Logic:**
  1. Find group by `id` (User inputs Group ID directly).
  2. **Concurrency Safety (CRITICAL):**
     - Use a **Firestore Transaction**.
     - Read the Group doc to get current `memberIds`.
     - Check modification safety.
     - Add current `userId` to `memberIds`.
     - Update user's `groupId`.
     - Write both changes atomically.

### C. Leave Group (`LeaveGroupUseCase`)
- **Logic:**
  1. **Concurrency Safety (CRITICAL):**
     - Use a **Firestore Transaction**.
     - Read the Group doc to get current `memberIds`.
     - Remove current `userId` from `memberIds`.
     - Update user's `groupId` to empty/null.
     - **Deletion Check:** If `memberIds` becomes empty, delete the Group document.
     - Write all changes atomically.

## 4. Data Layer: Repository Implementation
**Path:** `Data/Repository/GroupRepositoryImpl.swift`

- Implement `GroupRepository` protocol.
- Use `Firestore.firestore().runTransaction` for Join and Leave logic.
- Ensure atomicity for "Delete if empty" logic.

## 5. Presentation Layer: Integration
- Update `GroupStore` (or `SessionStore` if it manages group state).
- Inject `CreateGroupUseCase`, `JoinGroupUseCase`, and `LeaveGroupUseCase`.
- Connect `GroupFeedNoGroupView` buttons to these Store actions.
