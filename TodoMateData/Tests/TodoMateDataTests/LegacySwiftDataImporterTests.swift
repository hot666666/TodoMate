import Foundation
import GRDB
import Testing
@testable import TodoMateData
import TodoMateDomain

@Suite("Legacy SwiftData Importer Tests", .serialized)
struct LegacySwiftDataImporterTests {
  @Test("Imports Core Data SQLite records once")
  func importsLegacyRecordsOnce() async throws {
    let legacyURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("legacy-\(UUID().uuidString).store")
    let now = Date()

    try await Self.createLegacyStore(at: legacyURL, timestamp: now)

    let database = try GRDBDatabase(storage: .inMemory)
    try await withThrowingTaskGroup(of: Void.self) { group in
      for _ in 0 ..< 2 {
        group.addTask {
          try LegacySwiftDataImporter.importIfNeeded(from: [legacyURL], into: database.writer)
        }
      }
      try await group.waitForAll()
    }
    try LegacySwiftDataImporter.importIfNeeded(from: [legacyURL], into: database.writer)

    let todos = try await GRDBTodoRepository(database: database).readAll(
      query: .init(),
      useCache: false,
    )
    let memos = try await GRDBMemoRepository(database: database).readAllByUserId(
      "owner",
      useCache: false,
    )
    #expect(todos.map(\.content) == ["Legacy Todo"])
    #expect(todos.first?.status == .todo)
    #expect(memos.map(\.content) == ["Legacy Memo"])

    Self.removeDatabaseFiles(at: legacyURL)
  }

  @Test("Preserves valid rows and retries malformed records without overwriting local edits")
  func retriesMalformedRecords() async throws {
    let legacyURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("legacy-partial-\(UUID().uuidString).store")
    defer { Self.removeDatabaseFiles(at: legacyURL) }

    try await Self.createLegacyStore(
      at: legacyURL,
      timestamp: Date(),
      includeMalformedTodo: true,
    )

    let database = try GRDBDatabase(storage: .inMemory)
    let repository = GRDBTodoRepository(database: database)
    try LegacySwiftDataImporter.importIfNeeded(from: [legacyURL], into: database.writer)

    var importedTodo = try #require(try await repository.read(id: "todo-id"))
    importedTodo.content = "Local edit"
    try await repository.update(importedTodo)

    let partialCompletion = try await database.writer.read { databaseConnection in
      try String.fetchOne(
        databaseConnection,
        sql: "SELECT value FROM localMetadata WHERE key = ?",
        arguments: ["legacySwiftDataImportCompleted"],
      )
    }
    #expect(partialCompletion == nil)

    try LegacySwiftDataImporter.importIfNeeded(from: [legacyURL], into: database.writer)
    #expect(try await repository.read(id: "todo-id")?.content == "Local edit")

    let legacyDatabase = try DatabaseQueue(path: legacyURL.path)
    try await legacyDatabase.write { databaseConnection in
      try databaseConnection.execute(
        sql: "UPDATE ZSDTODO SET ZCONTENT = ? WHERE ZID = ?",
        arguments: ["Recovered", "malformed-todo-id"],
      )
    }

    try LegacySwiftDataImporter.importIfNeeded(from: [legacyURL], into: database.writer)

    let todos = try await repository.readAll(query: .init(), useCache: false)
    #expect(Set(todos.map(\.id)) == ["todo-id", "malformed-todo-id"])
    #expect(todos.first(where: { $0.id == "todo-id" })?.content == "Local edit")
    #expect(todos.first(where: { $0.id == "malformed-todo-id" })?.content == "Recovered")

    let finalCompletion = try await database.writer.read { databaseConnection in
      try String.fetchOne(
        databaseConnection,
        sql: "SELECT value FROM localMetadata WHERE key = ?",
        arguments: ["legacySwiftDataImportCompleted"],
      )
    }
    #expect(finalCompletion == "true")
  }

  @Test("Normalizes known local owner aliases and preserves remote identities")
  func normalizesKnownLocalOwnerAliases() async throws {
    let legacyURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("legacy-owner-\(UUID().uuidString).store")
    defer { Self.removeDatabaseFiles(at: legacyURL) }

    try await Self.createLegacyStore(
      at: legacyURL,
      timestamp: Date(),
      ownerID: "",
    )
    let legacyDatabase = try DatabaseQueue(path: legacyURL.path)
    try await legacyDatabase.write { databaseConnection in
      try databaseConnection.execute(
        sql: "UPDATE ZSDMEMO SET ZOWNERID = ?",
        arguments: ["firebase-user"],
      )
    }

    let database = try GRDBDatabase(storage: .inMemory)
    try LegacySwiftDataImporter.importIfNeeded(from: [legacyURL], into: database.writer)

    let owners = try await database.writer.read { databaseConnection in
      try (
        todo: TodoRecord.fetchOne(databaseConnection, key: "todo-id")?.ownerID,
        memo: MemoRecord.fetchOne(databaseConnection, key: "memo-id")?.ownerID,
      )
    }
    #expect(owners.todo == User.local.id)
    #expect(owners.memo == "firebase-user")
  }

  private static func createLegacyStore(
    at url: URL,
    timestamp: Date,
    includeMalformedTodo: Bool = false,
    ownerID: String = "owner",
  ) async throws {
    let database = try DatabaseQueue(path: url.path)
    try await database.write { databaseConnection in
      try databaseConnection.execute(sql: """
      CREATE TABLE ZSDTODO (
        ZID TEXT, ZCONTENT TEXT, ZSTATUSRAWVALUE TEXT, ZDETAIL TEXT,
        ZDATE DOUBLE, ZCREATEDAT DOUBLE, ZUPDATEDAT DOUBLE, ZOWNER TEXT,
        ZISDELETED INTEGER
      );
      CREATE TABLE ZSDMEMO (
        ZID TEXT, ZCONTENT TEXT, ZCREATEDAT DOUBLE, ZUPDATEDAT DOUBLE,
        ZOWNERID TEXT, ZISDELETED INTEGER
      );
      """)
      try databaseConnection.execute(
        sql: "INSERT INTO ZSDTODO VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
        arguments: [
          "todo-id", "Legacy Todo", "legacy-unknown-status", "detail",
          timestamp.timeIntervalSinceReferenceDate,
          timestamp.timeIntervalSinceReferenceDate,
          timestamp.timeIntervalSinceReferenceDate,
          ownerID, 0,
        ],
      )
      try databaseConnection.execute(
        sql: "INSERT INTO ZSDMEMO VALUES (?, ?, ?, ?, ?, ?)",
        arguments: [
          "memo-id", "Legacy Memo",
          timestamp.timeIntervalSinceReferenceDate,
          timestamp.timeIntervalSinceReferenceDate,
          ownerID, 0,
        ],
      )
      if includeMalformedTodo {
        try databaseConnection.execute(
          sql: "INSERT INTO ZSDTODO VALUES (?, NULL, ?, ?, ?, ?, ?, ?, ?)",
          arguments: [
            "malformed-todo-id", "시작 전", "detail",
            timestamp.timeIntervalSinceReferenceDate,
            timestamp.timeIntervalSinceReferenceDate,
            timestamp.timeIntervalSinceReferenceDate,
            ownerID, 0,
          ],
        )
      }
    }
  }

  private static func removeDatabaseFiles(at url: URL) {
    try? FileManager.default.removeItem(at: url)
    try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + "-wal"))
    try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + "-shm"))
  }
}
