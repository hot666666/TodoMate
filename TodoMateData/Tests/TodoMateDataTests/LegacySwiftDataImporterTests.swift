import Foundation
import GRDB
import Testing
@testable import TodoMateData

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
    #expect(memos.map(\.content) == ["Legacy Memo"])

    Self.removeDatabaseFiles(at: legacyURL)
  }

  private static func createLegacyStore(at url: URL, timestamp: Date) async throws {
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
          "todo-id", "Legacy Todo", "시작 전", "detail",
          timestamp.timeIntervalSinceReferenceDate,
          timestamp.timeIntervalSinceReferenceDate,
          timestamp.timeIntervalSinceReferenceDate,
          "owner", 0,
        ],
      )
      try databaseConnection.execute(
        sql: "INSERT INTO ZSDMEMO VALUES (?, ?, ?, ?, ?, ?)",
        arguments: [
          "memo-id", "Legacy Memo",
          timestamp.timeIntervalSinceReferenceDate,
          timestamp.timeIntervalSinceReferenceDate,
          "owner", 0,
        ],
      )
    }
  }

  private static func removeDatabaseFiles(at url: URL) {
    try? FileManager.default.removeItem(at: url)
    try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + "-wal"))
    try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + "-shm"))
  }
}
