//
//  LocalTodoRepositoryTests.swift
//  TodoMateDataTests
//
//  Created by agent on 1/11/26.
//

import Foundation
import SwiftData
import Testing
import TodoMateDomain

@testable import TodoMateData

@Suite("Local Todo Repository Tests", .serialized)
@MainActor
struct LocalTodoRepositoryTests {
  let repository: SwiftDataTodoRepositoryImpl
  let container: ModelContainer
  let testUserId = "local-user"

  init() async throws {
    // Setup in-memory SwiftData container
    let schema = Schema([SDTodo.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    container = try ModelContainer(for: schema, configurations: [config])
    repository = SwiftDataTodoRepositoryImpl(modelContainer: container)
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
    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)

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
    let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
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
}
