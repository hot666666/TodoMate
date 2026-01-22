//
//  DeletedItemsUseCaseTests.swift
//  TodoMateDomainTests
//
//  Created by agent on 1/22/26.
//

import Foundation
import Testing

@testable import TodoMateDomain

@Suite("Deleted Items UseCases Tests")
struct DeletedItemsUseCaseTests {
  // MARK: - FetchDeletedItemsUseCase Tests

  @Test("Fetch deleted items returns empty when no deleted items exist")
  func fetchDeletedItemsEmpty() async throws {
    // Given
    let repository = InMemoryDeletedItemsRepository()
    let useCase = FetchDeletedItemsUseCaseImpl(repository: repository)

    // When
    let result = try await useCase.run()

    // Then
    #expect(result.isEmpty)
  }

  @Test("Fetch deleted items returns both deleted todos and memos")
  func fetchDeletedItemsReturnsBoth() async throws {
    // Given
    let deletedTodo = Todo(owner: "user1", content: "Deleted Todo", in: Date())
    let deletedMemo = Memo(owner: "user1", content: "Deleted Memo", date: Date())

    let repository = InMemoryDeletedItemsRepository()
    await repository.setItems([.todo(deletedTodo), .memo(deletedMemo)])

    let useCase = FetchDeletedItemsUseCaseImpl(repository: repository)

    // When
    let result = try await useCase.run()

    // Then
    #expect(result.count == 2)
  }

  @Test("Fetch deleted items sorted by deletedAt descending (most recent first)")
  func fetchDeletedItemsSortedByDate() async throws {
    // Given
    let olderDate = Date().addingTimeInterval(-86400) // 1 day ago
    let newerDate = Date()

    let olderTodo = Todo(
      id: "old", content: "Older",
      date: olderDate, createdAt: olderDate, updatedAt: olderDate, owner: "user1",
    )
    let newerMemo = Memo(
      id: "new", content: "Newer",
      createdAt: newerDate, updatedAt: newerDate, owner: "user1",
    )

    let repository = InMemoryDeletedItemsRepository()
    await repository.setItems([.todo(olderTodo), .memo(newerMemo)])

    let useCase = FetchDeletedItemsUseCaseImpl(repository: repository)

    // When
    let result = try await useCase.run()

    // Then
    #expect(result.count == 2)
    #expect(result.first?.id == "new") // Newer item first
  }

  // MARK: - RestoreDeletedItemUseCase Tests

  @Test("Restore deleted item removes it from deleted items")
  func restoreDeletedItem() async throws {
    // Given
    let deletedTodo = Todo(owner: "user1", content: "Deleted Todo", in: Date())
    let repository = InMemoryDeletedItemsRepository()
    await repository.setItems([.todo(deletedTodo)])

    let useCase = RestoreDeletedItemUseCaseImpl(repository: repository)

    // When
    try await useCase.run(.todo(deletedTodo))

    // Then
    let restoreCount = await repository.restoreCallCount
    #expect(restoreCount == 1)
  }

  @Test("Restore multiple deleted items")
  func restoreMultipleItems() async throws {
    // Given
    let todo1 = Todo(owner: "user1", content: "Todo 1", in: Date())
    let todo2 = Todo(owner: "user1", content: "Todo 2", in: Date())
    let repository = InMemoryDeletedItemsRepository()
    await repository.setItems([.todo(todo1), .todo(todo2)])

    let useCase = RestoreDeletedItemUseCaseImpl(repository: repository)

    // When
    try await useCase.run([.todo(todo1), .todo(todo2)])

    // Then
    let restoreCount = await repository.restoreCallCount
    #expect(restoreCount == 2)
  }

  // MARK: - PermanentlyDeleteItemUseCase Tests

  @Test("Permanently delete item removes it from storage")
  func permanentlyDeleteItem() async throws {
    // Given
    let deletedTodo = Todo(owner: "user1", content: "To be deleted forever", in: Date())
    let repository = InMemoryDeletedItemsRepository()
    await repository.setItems([.todo(deletedTodo)])

    let useCase = PermanentlyDeleteItemUseCaseImpl(repository: repository)

    // When
    try await useCase.run(.todo(deletedTodo))

    // Then
    let deleteCount = await repository.permanentlyDeleteCallCount
    #expect(deleteCount == 1)
  }

  @Test("Permanently delete all items clears the trash")
  func permanentlyDeleteAllItems() async throws {
    // Given
    let todo = Todo(owner: "user1", content: "Todo", in: Date())
    let memo = Memo(owner: "user1", content: "Memo", date: Date())
    let repository = InMemoryDeletedItemsRepository()
    await repository.setItems([.todo(todo), .memo(memo)])

    let useCase = PermanentlyDeleteItemUseCaseImpl(repository: repository)

    // When
    try await useCase.runAll()

    // Then
    let deleteAllCount = await repository.permanentlyDeleteAllCallCount
    #expect(deleteAllCount == 1)
  }
}
