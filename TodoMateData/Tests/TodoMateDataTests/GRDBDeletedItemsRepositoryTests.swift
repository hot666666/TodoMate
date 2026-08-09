import Foundation
import Testing
@testable import TodoMateData
import TodoMateDomain

@Suite("Deleted Items Repository Tests", .serialized)
struct GRDBDeletedItemsRepositoryTests {
  let todoRepository: GRDBTodoRepository
  let memoRepository: GRDBMemoRepository
  let repository: GRDBDeletedItemsRepository

  init() throws {
    let database = try GRDBDatabase(storage: .inMemory)
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
    try await repository.restore(deletedTodo)
    #expect(try await todoRepository.read(id: todo.id) != nil)

    try await repository.permanentlyDeleteAll()
    #expect(try await repository.fetchAll().isEmpty)
  }
}
