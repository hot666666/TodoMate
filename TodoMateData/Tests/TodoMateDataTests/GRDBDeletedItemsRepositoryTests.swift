import Foundation
import Testing
@testable import TodoMateData
import TodoMateDomain

@Suite("Deleted Items Repository Tests", .serialized)
struct GRDBDeletedItemsRepositoryTests {
  let database: GRDBDatabase
  let todoRepository: GRDBTodoRepository
  let memoRepository: GRDBMemoRepository
  let repository: GRDBDeletedItemsRepository

  init() throws {
    let database = try GRDBDatabase(storage: .inMemory)
    self.database = database
    todoRepository = GRDBTodoRepository(database: database)
    memoRepository = GRDBMemoRepository(database: database)
    repository = GRDBDeletedItemsRepository(database: database)
  }

  @Test("Restores and permanently deletes soft-deleted items")
  func restoreAndDelete() async throws {
    let todo = Todo(owner: "owner", content: "Todo")
    let memo = Memo(owner: "owner", content: "Memo")
    try await todoRepository.create(todo)
    try await memoRepository.create(memo)
    try await todoRepository.delete(todo.id)
    try await memoRepository.delete(memo)

    let deleted = try await repository.fetchAll()
    #expect(deleted.count == 2)

    guard let deletedTodo = deleted.first(where: { item in
      if case .todo = item { return true }
      return false
    }) else {
      Issue.record("Deleted todo was not found")
      return
    }
    guard case let .todo(deletedTodoValue, snapshotRevision) = deletedTodo else {
      Issue.record("Expected a todo snapshot")
      return
    }
    let todoID = todo.id
    let storedRecord = try await database.writer.read { databaseConnection in
      try TodoRecord.fetchOne(databaseConnection, key: todoID)
    }
    #expect(deletedTodoValue.id == todo.id)
    #expect(snapshotRevision == storedRecord?.localRevision)
    #expect(deletedTodoValue.updatedAt == storedRecord?.deletedAt)
    try await repository.restore(deletedTodo)
    #expect(try await todoRepository.read(id: todo.id) != nil)

    try await repository.permanentlyDeleteAll()
    #expect(try await repository.fetchAll().isEmpty)
  }

  @Test("A stale trash snapshot cannot permanently delete a restored item")
  func staleSnapshotCannotDeleteRestoredItem() async throws {
    let todo = Todo(owner: "owner", content: "Keep me")
    try await todoRepository.create(todo)
    try await todoRepository.delete(todo.id)

    let staleItem = try #require(try await repository.fetchAll().first)
    try await repository.restore(staleItem)
    try await repository.permanentlyDelete(staleItem)

    #expect(try await todoRepository.read(id: todo.id)?.content == "Keep me")
  }

  @Test("A stale trash snapshot cannot restore a newer deletion")
  func staleSnapshotCannotRestoreNewerDeletion() async throws {
    let todo = Todo(owner: "owner", content: "Stay deleted")
    try await todoRepository.create(todo)
    try await todoRepository.delete(todo.id)

    let staleItem = try #require(try await repository.fetchAll().first)
    try await repository.restore(staleItem)
    try await todoRepository.delete(todo.id)
    let currentItem = try #require(try await repository.fetchAll().first)

    try await repository.restore(staleItem)

    #expect(try await todoRepository.read(id: todo.id) == nil)
    #expect(try await repository.fetchAll() == [currentItem])
  }

  @Test("Permanently deletes an unchanged active memo")
  func permanentlyDeletesActiveMemo() async throws {
    let memo = Memo(owner: "owner", content: "Clear me")
    try await memoRepository.create(memo)

    try await repository.permanentlyDelete(.memo(memo))

    let memoID = memo.id
    let storedRecord = try await database.writer.read { databaseConnection in
      try MemoRecord.fetchOne(databaseConnection, key: memoID)
    }
    #expect(storedRecord == nil)
  }

  @Test("A stale active memo snapshot cannot delete a newer edit")
  func staleActiveMemoCannotDeleteNewerEdit() async throws {
    let staleMemo = Memo(
      content: "Original",
      createdAt: .distantPast,
      updatedAt: .distantPast,
      owner: "owner",
    )
    try await memoRepository.create(staleMemo)
    try await memoRepository.update(staleMemo.withUpdatedContent("Newer"))

    try await repository.permanentlyDelete(.memo(staleMemo))

    #expect(try await memoRepository.read(id: staleMemo.id)?.content == "Newer")
  }
}
