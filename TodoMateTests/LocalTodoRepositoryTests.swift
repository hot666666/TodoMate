//
//  LocalTodoRepositoryTests.swift
//  TodoMateTests
//
//  Created by agent on 1/11/26.
//

import Foundation
import SwiftData
import Testing

@testable import TodoMate

@Suite("Local Todo Repository Tests", .serialized)
@MainActor
struct LocalTodoRepositoryTests {
  let repository: LocalTodoRepositoryImpl
  let container: ModelContainer
  let testUserId = "local-user"

  init() async throws {
    // Setup in-memory SwiftData container
    let schema = Schema([SDTodo.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    container = try ModelContainer(for: schema, configurations: [config])
    repository = LocalTodoRepositoryImpl(modelContext: container.mainContext)
  }

  // MARK: - Create & Read

  @Test("Creates and reads a single todo locally")
  func createAndReadTodo() async throws {
    let todo = Todo(owner: testUserId, content: "Local Todo", detail: "Detail")
    try repository.create(todo)

    let query = TodoQuery().owner(userId: testUserId)
    let results = try await repository.readAll(query: query, source: .cache)

    let found = results.first { $0.id == todo.id }
    #expect(found != nil)
    #expect(found?.content == "Local Todo")
    #expect(found?.detail == "Detail")
  }

  // MARK: - Update

  @Test("Updates existing todo locally")
  func updateTodo() async throws {
    var todo = Todo(owner: testUserId, content: "Original")
    try repository.create(todo)

    todo.content = "Updated"
    todo.status = .complete
    try repository.update(todo)

    let query = TodoQuery().owner(userId: testUserId)
    let results = try await repository.readAll(query: query, source: .cache)
    let updated = results.first { $0.id == todo.id }

    #expect(updated?.content == "Updated")
    #expect(updated?.status == .complete)
  }

  // MARK: - Delete

  @Test("Deletes todo locally")
  func deleteTodo() async throws {
    let todo = Todo(owner: testUserId, content: "To be deleted")
    try repository.create(todo)

    try await repository.delete(todo.id)

    let query = TodoQuery().owner(userId: testUserId)
    let results = try await repository.readAll(query: query, source: .cache)
    #expect(!results.contains { $0.id == todo.id })
  }
}
