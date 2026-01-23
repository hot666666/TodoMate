//
//  ImportLegacyDataUseCaseTests.swift
//  TodoMateDomainTests
//
//  Created by hs on 2025-01-23.
//

import Testing

@testable import TodoMateDomain

@Suite("Import Legacy Data UseCase Tests")
struct ImportLegacyDataUseCaseTests {
  var useCase: ImportLegacyDataUseCaseImpl!
  var legacyRepo: MockLegacyImportRepository!
  var stateRepo: MockLegacyImportStateRepository!
  var todoRepo: LocalInMemoryTodoRepository!
  var memoRepo: LocalInMemoryMemoRepository!

  init() {
    legacyRepo = MockLegacyImportRepository()
    stateRepo = MockLegacyImportStateRepository()
    todoRepo = LocalInMemoryTodoRepository()
    memoRepo = LocalInMemoryMemoRepository()
    useCase = ImportLegacyDataUseCaseImpl(
      legacyRepository: legacyRepo,
      stateRepository: stateRepo,
      todoRepository: todoRepo,
      memoRepository: memoRepo,
    )
  }

  @Test("Memo Import: Creates new memo if exists in legacy")
  func importMemoIfExists() async throws {
    // Given
    let userId = "user1"
    let memo = Memo(owner: userId, content: "Legacy Memo")
    legacyRepo.memoToReturn = memo

    // When
    for try await _ in useCase.execute(userId: userId) {}

    // Then
    let createdMemos = try await memoRepo.readAllByUserId(userId, useCache: true)
    #expect(createdMemos.count == 1)
    #expect(createdMemos.first?.content == "Legacy Memo")
  }

  @Test("Guard Clause: Returns immediately if already imported")
  func executeReturnsImmediatelyIfImported() async throws {
    // Given
    stateRepo.isImportedValue = true
    let userId = "user1"

    // When
    var didYield = false
    for try await _ in useCase.execute(userId: userId) {
      didYield = true
    }

    // Then
    #expect(didYield == false)
  }

  @Test("Todo Import: Imports all items across pages")
  func importTodosPaginated() async throws {
    // Given
    let userId = "user1"
    let todo1 = Todo(owner: userId, content: "Todo 1", in: .now)
    let todo2 = Todo(owner: userId, content: "Todo 2", in: .now)
    let todo3 = Todo(owner: userId, content: "Todo 3", in: .now)

    // Batch 1 has 2 items, Batch 2 has 1 item
    legacyRepo.batches = [
      [todo1, todo2],
      [todo3],
    ]
    legacyRepo.totalCount = 3

    // When
    var progressValues: [Double] = []
    for try await progress in useCase.execute(userId: userId) {
      progressValues.append(progress)
    }

    // Then
    // 1. Check all todos created in local repo
    let savedTodos = try await todoRepo.readAll(
      query: .init(filters: [.owner(userId: userId)]), useCache: true,
    )
    #expect(savedTodos.count == 3)

    // 2. Check Progress:
    // Batch 1 (2 items) -> 2/3 = 0.66
    // Batch 2 (1 item) -> 3/3 = 1.0
    #expect(progressValues.contains(shouldMatch: 0.66))
    #expect(progressValues.last == 1.0)

    // 3. Check State Updated
    #expect(stateRepo.isImportedValue == true)
  }

  @Test("Todo Import: Skips duplicates")
  func importTodosSkippingDuplicates() async throws {
    // Given
    let userId = "user1"
    let todo1 = Todo(owner: userId, content: "Todo 1", in: .now)
    let todo2 = Todo(owner: userId, content: "Todo 2", in: .now)

    // Local Repo already has todo1
    try await todoRepo.create(todo1)

    legacyRepo.batches = [[todo1, todo2]]
    legacyRepo.totalCount = 2

    // When
    for try await _ in useCase.execute(userId: userId) {}

    // Then
    let savedTodos = try await todoRepo.readAll(
      query: .init(filters: [.owner(userId: userId)]), useCache: true,
    )

    // Since LocalInMemoryTodoRepository.read finds based on ID, it returns existing todo1.
    #expect(savedTodos.count == 2)
    #expect(savedTodos.contains(where: { $0.id == todo1.id }))
    #expect(savedTodos.contains(where: { $0.id == todo2.id }))
  }
}

// MARK: - Mocks for Test

final class LocalInMemoryTodoRepository: TodoRepository, @unchecked Sendable {
  var todos: [Todo] = []

  func create(_ todo: Todo) async throws { todos.append(todo) }
  func update(_ todo: Todo) async throws {
    if let i = todos.firstIndex(where: { $0.id == todo.id }) { todos[i] = todo }
  }

  func delete(_ id: String) async throws { todos.removeAll { $0.id == id } }
  func read(id: String) async throws -> Todo? { todos.first { $0.id == id } }
  func readAll(query: TodoQuery, useCache _: Bool) async throws -> [Todo] {
    // Simple filter support for test
    var result = todos
    for filter in query.filters {
      switch filter {
      case let .owner(userId): result = result.filter { $0.owner == userId }
      default: break
      }
    }
    return result
  }

  func observeTodos(query _: TodoQuery) -> AsyncStream<[Todo]> { .init { $0.finish() } }
  func fetchCount(query _: TodoQuery) async throws -> Int { todos.count }
}

final class LocalInMemoryMemoRepository: MemoRepository, @unchecked Sendable {
  var memos: [Memo] = []

  func create(_ memo: Memo) async throws { memos.append(memo) }
  func update(_ memo: Memo) async throws {
    if let i = memos.firstIndex(where: { $0.id == memo.id }) { memos[i] = memo }
  }

  func delete(_ memo: Memo) async throws { memos.removeAll { $0.id == memo.id } }
  func read(id: String) async throws -> Memo? { memos.first { $0.id == id } }
  func readAllByUserId(_ userId: String, useCache _: Bool) async throws -> [Memo] {
    memos.filter { $0.owner == userId }
  }

  func readAllByUserIds(_: [String], useCache _: Bool) async throws -> [Memo] { [] }
  func fetchCount(userId _: String) async throws -> Int { memos.count }
  func observeMemos() -> AsyncStream<[Memo]> { .init { $0.finish() } }
}

final class MockLegacyImportRepository: LegacyImportRepository, @unchecked Sendable {
  var batches: [[Todo]] = []
  var memoToReturn: Memo?
  var totalCount: Int = 0

  private var currentBatchIndex = 0

  func fetchLegacyTodos(userId _: String, lastSnapshot _: Any?, limit _: Int) async throws -> (
    todos: [Todo], lastSnapshot: Any?,
  ) {
    guard currentBatchIndex < batches.count else {
      return ([], nil)
    }

    let batch = batches[currentBatchIndex]
    currentBatchIndex += 1

    // Return a dummy snapshot if there are more batches
    let nextSnapshot: Any? =
      currentBatchIndex < batches.count ? "Snapshot-\(currentBatchIndex)" : nil
    return (batch, nextSnapshot)
  }

  func fetchLegacyMemo(userId _: String) async throws -> Memo? {
    memoToReturn
  }

  func fetchLegacyTodoCount(userId _: String) async throws -> Int {
    totalCount
  }
}

final class MockLegacyImportStateRepository: LegacyImportStateRepository, @unchecked Sendable {
  var isImportedValue = false
  func isImported() -> Bool { isImportedValue }
  func setImported(_ imported: Bool) { isImportedValue = imported }
}

extension [Double] {
  func contains(shouldMatch value: Double, accuracy: Double = 0.01) -> Bool {
    contains { abs($0 - value) < accuracy }
  }
}
