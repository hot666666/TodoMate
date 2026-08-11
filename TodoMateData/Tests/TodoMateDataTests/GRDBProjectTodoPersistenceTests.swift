import Foundation
import Testing
import TodoMateApplication
@testable import TodoMateData
import TodoMateDomain

@Suite("GRDB Project Todo persistence")
struct GRDBProjectTodoPersistenceTests {
  @Test("Project-scoped Todo survives reopening and excludes another Project")
  func restoreAfterReopen() async throws {
    let databaseURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("TodoMateProjectTodo-\(UUID().uuidString).sqlite")
    defer {
      for suffix in ["", "-shm", "-wal"] {
        try? FileManager.default.removeItem(atPath: databaseURL.path + suffix)
      }
    }
    let firstProjectID = ProjectID(rawValue: "project-1")
    let secondProjectID = ProjectID(rawValue: "project-2")
    let todoID = TodoID(rawValue: "todo-1")
    let instant = Date(timeIntervalSince1970: 1_786_363_200)

    do {
      let database = try GRDBDatabase(storage: .file(databaseURL))
      let firstProjectClient = ProjectClient.grdb(
        database: database,
        generateID: { firstProjectID },
        now: { instant },
      )
      let secondProjectClient = ProjectClient.grdb(
        database: database,
        generateID: { secondProjectID },
        now: { instant },
      )
      _ = try await firstProjectClient.createLocal(.init(name: "First"))
      _ = try await secondProjectClient.createLocal(.init(name: "Second"))
      let todoClient = TodoClient.grdb(
        database: database,
        generateID: { todoID },
        now: { instant },
      )
      _ = try await todoClient.create(.init(projectID: firstProjectID, title: "First Todo"))
    }

    let reopened = try GRDBDatabase(storage: .file(databaseURL))
    let client = TodoClient.grdb(database: reopened)
    let firstTodos = try await firstValue(from: client.observe(firstProjectID))
    let secondTodos = try await firstValue(from: client.observe(secondProjectID))

    #expect(firstTodos.map(\.id) == [todoID])
    #expect(firstTodos.first?.projectID == firstProjectID)
    #expect(firstTodos.first?.title.value == "First Todo")
    #expect(secondTodos.isEmpty)
    #expect(
      try await GRDBTodoRepository(database: reopened)
        .readAll(query: TodoQuery(), useCache: false)
        .isEmpty,
    )
  }

  @Test("Unknown Project write fails without an orphan Todo")
  func rejectUnknownProject() async throws {
    let database = try GRDBDatabase(storage: .inMemory)
    let client = TodoClient.grdb(database: database, generateID: { .init(rawValue: "todo-1") })

    await #expect(throws: (any Error).self) {
      try await client.create(.init(projectID: .init(rawValue: "missing"), title: "Orphan"))
    }
    #expect(try await firstValue(from: client.observe(.init(rawValue: "missing"))).isEmpty)
  }

  private func firstValue<T>(from stream: AsyncStream<T>) async throws -> T {
    for await value in stream {
      return value
    }
    throw StreamError.finishedWithoutValue
  }

  private enum StreamError: Error { case finishedWithoutValue }
}
