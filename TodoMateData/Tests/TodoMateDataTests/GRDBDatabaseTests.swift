import Foundation
import GRDB
import Testing
@testable import TodoMateData
import TodoMateDomain

@Suite("GRDB Database Tests", .serialized)
struct GRDBDatabaseTests {
  @Test("Canonicalizes only reserved local owner aliases")
  func canonicalizesOnlyReservedLocalOwnerAliases() {
    #expect(LocalAuthorID.canonicalizing("") == User.local.id)
    #expect(LocalAuthorID.canonicalizing(EntityConstant.User.stubId) == User.local.id)
    #expect(LocalAuthorID.canonicalizing(User.local.id) == User.local.id)
    #expect(LocalAuthorID.canonicalizing("firebase-user") == "firebase-user")
    #expect(LocalAuthorID.canonicalizing("stubUser") == "stubUser")
    #expect(LocalAuthorID.canonicalizing("TESTUSER") == "TESTUSER")
    #expect(LocalAuthorID.canonicalizing(" testUser ") == " testUser ")
  }

  @Test("Uses canonical metadata column names")
  func canonicalMetadataColumns() async throws {
    let database = try GRDBDatabase(storage: .inMemory)

    let todoColumns = try await database.writer.read { databaseConnection in
      try Set(databaseConnection.columns(in: TodoRecord.databaseTableName).map(\.name))
    }
    let memoColumns = try await database.writer.read { databaseConnection in
      try Set(databaseConnection.columns(in: MemoRecord.databaseTableName).map(\.name))
    }

    #expect(todoColumns.isSuperset(of: [
      "id", "ownerId", "createdAt", "updatedAt", "deletedAt", "localRevision",
    ]))
    #expect(memoColumns.isSuperset(of: [
      "id", "ownerId", "createdAt", "updatedAt", "deletedAt", "localRevision",
    ]))
    #expect(!todoColumns.contains("owner"))
    #expect(!todoColumns.contains("isDeleted"))
    #expect(!memoColumns.contains("owner"))
    #expect(!memoColumns.contains("isDeleted"))
  }

  @Test("Migrates the initial GRDB metadata schema")
  func migratesInitialMetadataSchema() async throws {
    let databaseURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("metadata-migration-\(UUID().uuidString).sqlite")
    let timestamp = Date(timeIntervalSince1970: 123)

    try await Self.createInitialDatabase(at: databaseURL, timestamp: timestamp)

    do {
      let database = try GRDBDatabase(storage: .file(databaseURL))
      let records = try await database.writer.read { databaseConnection in
        try (
          originalTodo: TodoRecord.fetchOne(databaseConnection, key: "todo-id"),
          stubTodo: TodoRecord.fetchOne(databaseConnection, key: "stub-todo-id"),
          emptyOwnerMemo: MemoRecord.fetchOne(databaseConnection, key: "empty-memo-id"),
          remoteOwnerMemo: MemoRecord.fetchOne(databaseConnection, key: "remote-memo-id"),
        )
      }
      #expect(records.originalTodo?.ownerID == "owner-id")
      #expect(records.originalTodo?.deletedAt == timestamp)
      #expect(records.originalTodo?.localRevision == 1)
      #expect(records.stubTodo?.ownerID == User.local.id)
      #expect(records.emptyOwnerMemo?.ownerID == User.local.id)
      #expect(records.remoteOwnerMemo?.ownerID == "firebase-user")
    }

    Self.removeDatabaseFiles(at: databaseURL)
  }

  @Test("Read-only database exposes queries and rejects writes")
  func readOnlyDatabase() async throws {
    let databaseURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("read-only-\(UUID().uuidString).sqlite")

    do {
      let writableDatabase = try GRDBDatabase(storage: .file(databaseURL))
      let repository = GRDBTodoRepository(database: writableDatabase)
      try await repository.create(Todo(owner: "owner-id", content: "Read only"))

      guard let readOnlyDatabase = try GRDBReadOnlyDatabase(storage: .file(databaseURL)) else {
        Issue.record("Expected a read-only database with the current schema")
        return
      }
      let reader = GRDBTodoReader(database: readOnlyDatabase)

      let todos = try await reader.fetch(query: TodoQuery().owner(userId: "owner-id"))
      #expect(todos.map(\.content) == ["Read only"])
      await #expect(throws: DatabaseError.self) {
        try await readOnlyDatabase.reader.read { databaseConnection in
          try databaseConnection.execute(sql: "DELETE FROM todo")
        }
      }
    }

    Self.removeDatabaseFiles(at: databaseURL)
  }

  @Test("Read-only database does not create missing storage")
  func readOnlyDatabaseDoesNotCreateStorage() throws {
    let directoryURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("missing-read-only-\(UUID().uuidString)", isDirectory: true)
    let databaseURL = directoryURL.appendingPathComponent("TodoMate.sqlite")
    defer { try? FileManager.default.removeItem(at: directoryURL) }

    let database = try GRDBReadOnlyDatabase(storage: .file(databaseURL))

    #expect(database == nil)
    #expect(!FileManager.default.fileExists(atPath: directoryURL.path))
  }

  private static func createInitialDatabase(at url: URL, timestamp: Date) async throws {
    let queue = try DatabaseQueue(path: url.path)
    var migrator = DatabaseMigrator()
    migrator.registerMigration("createLocalItems", migrate: createInitialSchema(in:))
    try migrator.migrate(queue)
    try await queue.write { databaseConnection in
      try databaseConnection.execute(
        sql: """
        INSERT INTO todo
          (id, content, status, detail, date, createdAt, updatedAt, owner, isDeleted)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        arguments: [
          "todo-id", "Legacy", "시작 전", "", timestamp, timestamp, timestamp, "owner-id", true,
        ],
      )
      try databaseConnection.execute(
        sql: """
        INSERT INTO todo
          (id, content, status, detail, date, createdAt, updatedAt, owner, isDeleted)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        arguments: [
          "stub-todo-id", "Stub", "시작 전", "", timestamp, timestamp, timestamp,
          EntityConstant.User.stubId, false,
        ],
      )
      try databaseConnection.execute(
        sql: """
        INSERT INTO memo (id, content, createdAt, updatedAt, owner, isDeleted)
        VALUES (?, ?, ?, ?, ?, ?), (?, ?, ?, ?, ?, ?)
        """,
        arguments: [
          "empty-memo-id", "Empty owner", timestamp, timestamp, "", false,
          "remote-memo-id", "Remote owner", timestamp, timestamp, "firebase-user", false,
        ],
      )
    }
  }

  private static func createInitialSchema(in databaseConnection: Database) throws {
    try databaseConnection.create(table: "todo") { table in
      table.column("id", .text).primaryKey()
      table.column("content", .text).notNull()
      table.column("status", .text).notNull()
      table.column("detail", .text).notNull()
      table.column("date", .datetime).notNull()
      table.column("createdAt", .datetime).notNull()
      table.column("updatedAt", .datetime).notNull()
      table.column("owner", .text).notNull()
      table.column("isDeleted", .boolean).notNull().defaults(to: false)
    }
    try databaseConnection.create(table: "memo") { table in
      table.column("id", .text).primaryKey()
      table.column("content", .text).notNull()
      table.column("createdAt", .datetime).notNull()
      table.column("updatedAt", .datetime).notNull()
      table.column("owner", .text).notNull()
      table.column("isDeleted", .boolean).notNull().defaults(to: false)
    }
    try databaseConnection.create(index: "todo_by_date", on: "todo", columns: ["date"])
    try databaseConnection.create(
      index: "todo_by_owner_date",
      on: "todo",
      columns: ["owner", "date"],
    )
    try databaseConnection.create(
      index: "memo_by_owner_updatedAt",
      on: "memo",
      columns: ["owner", "updatedAt"],
    )
    try databaseConnection.create(table: "localMetadata") { table in
      table.column("key", .text).primaryKey()
      table.column("value", .text).notNull()
    }
  }

  private static func removeDatabaseFiles(at url: URL) {
    try? FileManager.default.removeItem(at: url)
    try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + "-wal"))
    try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + "-shm"))
  }
}
