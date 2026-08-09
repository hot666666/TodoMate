//
//  LocalTodoRepositoryTests.swift
//  TodoMateDataTests
//
//  Created by agent on 1/11/26.
//

import Foundation
import Testing
@testable import TodoMateData
import TodoMateDomain

@Suite("Local Todo Repository Tests", .serialized)
struct LocalTodoRepositoryTests {
  let database: GRDBDatabase
  let repository: GRDBTodoRepository
  let testUserId = "local-user"

  init() async throws {
    database = try GRDBDatabase(storage: .inMemory)
    repository = GRDBTodoRepository(database: database)
  }

  // MARK: - Create & Read

  @Test("Creates and reads a single todo locally")
  func createAndReadTodo() async throws {
    let todo = Todo(owner: testUserId, content: "Local Todo", detail: "Detail")
    try await repository.create(todo)

    let query = TodoQuery().owner(userId: testUserId)
    let results = try await repository.readAll(query: query, useCache: true)

    let found = results.first { $0.id == todo.id }
    #expect(found != nil)
    #expect(found?.content == "Local Todo")
    #expect(found?.detail == "Detail")
  }

  // MARK: - Update

  @Test("Updates existing todo locally")
  func updateTodo() async throws {
    var todo = Todo(owner: testUserId, content: "Original")
    try await repository.create(todo)

    todo.content = "Updated"
    todo.status = .complete
    try await repository.update(todo)

    let query = TodoQuery().owner(userId: testUserId)
    let results = try await repository.readAll(query: query, useCache: true)
    let updated = results.first { $0.id == todo.id }

    #expect(updated?.content == "Updated")
    #expect(updated?.status == .complete)
  }

  @Test("Updating a missing todo fails")
  func updateMissingTodoFails() async throws {
    let todo = Todo(owner: testUserId, content: "Missing")
    var didThrow = false
    do {
      try await repository.update(todo)
    } catch {
      didThrow = true
    }
    #expect(didThrow)
  }

  // MARK: - Delete

  @Test("Deletes todo locally")
  func deleteTodo() async throws {
    let todo = Todo(owner: testUserId, content: "To be deleted")
    try await repository.create(todo)

    try await repository.delete(todo.id)

    let query = TodoQuery().owner(userId: testUserId)
    let results = try await repository.readAll(query: query, useCache: true)
    #expect(!results.contains { $0.id == todo.id })
  }

  // MARK: - Fetch Count

  @Test("Fetches todo count with query and respects isDeleted")
  func fetchCount() async throws {
    let today = Date()
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: today)
    let endOfDay = try #require(calendar.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1))

    // 1. One active today
    let todo1 = Todo(
      id: UUID().uuidString,
      content: "Active Today",
      date: today,
      createdAt: today,
      updatedAt: today,
      owner: testUserId,
      isDeleted: false,
    )

    // 2. One deleted today
    let todo2 = Todo(
      id: UUID().uuidString,
      content: "Deleted Today",
      date: today,
      createdAt: today,
      updatedAt: today,
      owner: testUserId,
      isDeleted: true,
    )

    // 3. One active tomorrow (out of range)
    let tomorrow = try #require(calendar.date(byAdding: .day, value: 1, to: today))
    let todo3 = Todo(
      id: UUID().uuidString,
      content: "Active Tomorrow",
      date: tomorrow,
      createdAt: tomorrow,
      updatedAt: tomorrow,
      owner: testUserId,
      isDeleted: false,
    )

    try await repository.create(todo1)
    try await repository.create(todo2)
    try await repository.create(todo3)

    let query = TodoQuery(filters: [.dateRange(startOfDay ... endOfDay)])
    let count = try await repository.fetchCount(query: query)

    #expect(count == 1)
  }

  @Test("Applies owner and status filters")
  func appliesAllFilters() async throws {
    try await repository.create(Todo(owner: testUserId, content: "Mine", status: .inProgress))
    try await repository.create(Todo(owner: "other", content: "Other", status: .inProgress))
    try await repository.create(Todo(owner: testUserId, content: "Done", status: .complete))

    let results = try await repository.readAll(
      query: TodoQuery().owner(userId: testUserId).status(.inProgress),
      useCache: false,
    )
    #expect(results.map(\.content) == ["Mine"])
  }

  @Test("Observation emits database changes")
  func observationEmitsChanges() async throws {
    let stream = repository.observeTodos(query: TodoQuery().owner(userId: testUserId))
    var iterator = stream.makeAsyncIterator()
    #expect(await iterator.next()?.isEmpty == true)

    try await repository.create(Todo(owner: testUserId, content: "Observed"))

    let updated = await iterator.next()
    #expect(updated?.map(\.content) == ["Observed"])
  }
}
