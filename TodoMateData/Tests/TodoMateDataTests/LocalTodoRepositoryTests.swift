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
    let originalDate = Date(timeIntervalSince1970: 1)
    var todo = Todo(
      content: "Original",
      createdAt: originalDate,
      updatedAt: originalDate,
      owner: testUserId,
    )
    try await repository.create(todo)

    todo.content = "Updated"
    todo.status = .complete
    try await repository.update(todo)

    let query = TodoQuery().owner(userId: testUserId)
    let results = try await repository.readAll(query: query, useCache: true)
    let updated = results.first { $0.id == todo.id }

    #expect(updated?.content == "Updated")
    #expect(updated?.status == .complete)
    #expect(updated?.updatedAt ?? originalDate > originalDate)

    let todoID = todo.id
    let record = try await database.writer.read { databaseConnection in
      try TodoRecord.fetchOne(databaseConnection, key: todoID)
    }
    #expect(record?.createdAt == originalDate)
    #expect(record?.localRevision == 2)
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

  @Test("Rejects an update after the todo was deleted")
  func updateDeletedTodoFails() async throws {
    var todo = Todo(owner: testUserId, content: "Original")
    try await repository.create(todo)
    try await repository.delete(todo.id)

    todo.content = "Stale update"
    var didThrow = false
    do {
      try await repository.update(todo)
    } catch {
      didThrow = true
    }

    #expect(didThrow)
    let todoID = todo.id
    let record = try await database.writer.read { databaseConnection in
      try TodoRecord.fetchOne(databaseConnection, key: todoID)
    }
    #expect(record?.content == "Original")
    #expect(record?.deletedAt != nil)
    #expect(record?.localRevision == 2)
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

  @Test("Observation emits metadata-only revisions")
  func observationEmitsMetadataOnlyRevision() async throws {
    let stream = repository.observeTodos(query: TodoQuery().owner(userId: testUserId))
    var iterator = stream.makeAsyncIterator()
    #expect(await iterator.next()?.isEmpty == true)

    let todo = Todo(
      content: "Unchanged",
      date: .now,
      createdAt: .distantPast,
      updatedAt: .distantPast,
      owner: testUserId,
    )
    try await repository.create(todo)
    let inserted = try #require(await iterator.next()?.first)

    try await repository.update(inserted)
    let revised = try #require(await iterator.next()?.first)

    #expect(revised.content == inserted.content)
    #expect(revised.updatedAt != inserted.updatedAt)
    let todoID = revised.id
    let localRevision = try await database.writer.read { databaseConnection in
      try TodoRecord.fetchOne(databaseConnection, key: todoID)?.localRevision
    }
    #expect(localRevision == 2)
  }

  @Test("Observation emits changes written through another database pool")
  func observationEmitsCrossPoolChanges() async throws {
    let databaseURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("cross-pool-\(UUID().uuidString).sqlite")

    do {
      let observingDatabase = try GRDBDatabase(storage: .file(databaseURL))
      let writingDatabase = try GRDBDatabase(storage: .file(databaseURL))
      let observingRepository = GRDBTodoRepository(database: observingDatabase)
      let writingRepository = GRDBTodoRepository(database: writingDatabase)
      let stream = observingRepository.observeTodos(query: TodoQuery().owner(userId: testUserId))
      var iterator = stream.makeAsyncIterator()

      #expect(await iterator.next()?.isEmpty == true)
      try await writingRepository.create(Todo(owner: testUserId, content: "External"))

      let updated = await iterator.next()
      #expect(updated?.map(\.content) == ["External"])
    }

    try? FileManager.default.removeItem(at: databaseURL)
    try? FileManager.default.removeItem(at: URL(fileURLWithPath: databaseURL.path + "-wal"))
    try? FileManager.default.removeItem(at: URL(fileURLWithPath: databaseURL.path + "-shm"))
  }
}
