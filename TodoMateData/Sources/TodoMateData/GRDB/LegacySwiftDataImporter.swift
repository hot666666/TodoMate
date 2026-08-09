import Foundation
import GRDB

enum LegacySwiftDataImporter {
  private static let completionKey = "legacySwiftDataImportCompleted"

  static func importIfNeeded(
    from storeURLs: [URL],
    into writer: any DatabaseWriter,
  ) throws {
    guard !storeURLs.isEmpty else { return }
    let isComplete = try writer.read { databaseConnection in
      try String.fetchOne(
        databaseConnection,
        sql: "SELECT value FROM localMetadata WHERE key = ?",
        arguments: [completionKey],
      ) != nil
    }
    guard !isComplete else { return }

    var todosByID: [String: TodoRecord] = [:]
    var memosByID: [String: MemoRecord] = [:]

    for url in storeURLs where FileManager.default.fileExists(atPath: url.path) {
      let records = try readLegacyStore(at: url)
      for todo in records.todos where todo.updatedAt > (todosByID[todo.id]?.updatedAt ?? .distantPast) {
        todosByID[todo.id] = todo
      }
      for memo in records.memos where memo.updatedAt > (memosByID[memo.id]?.updatedAt ?? .distantPast) {
        memosByID[memo.id] = memo
      }
    }

    try writer.write { databaseConnection in
      for todo in todosByID.values {
        try todo.insert(databaseConnection, onConflict: .replace)
      }
      for memo in memosByID.values {
        try memo.insert(databaseConnection, onConflict: .replace)
      }
      try databaseConnection.execute(
        sql: "INSERT INTO localMetadata (key, value) VALUES (?, ?)",
        arguments: [completionKey, "true"],
      )
    }
  }

  private static func readLegacyStore(at url: URL) throws -> (todos: [TodoRecord], memos: [MemoRecord]) {
    var configuration = Configuration()
    configuration.readonly = true
    let database = try DatabaseQueue(path: url.path, configuration: configuration)

    return try database.read { databaseConnection in
      let todos = try databaseConnection.tableExists("ZSDTODO")
        ? readTodos(from: databaseConnection) : []
      let memos = try databaseConnection.tableExists("ZSDMEMO")
        ? readMemos(from: databaseConnection) : []
      return (todos, memos)
    }
  }

  private static func readTodos(from databaseConnection: Database) throws -> [TodoRecord] {
    try Row.fetchAll(
      databaseConnection,
      sql: """
      SELECT ZID, ZCONTENT, ZSTATUSRAWVALUE, ZDETAIL, ZDATE, ZCREATEDAT,
             ZUPDATEDAT, ZOWNER, ZISDELETED
      FROM ZSDTODO
      """,
    ).compactMap { row in
      guard let id: String = row["ZID"],
            let content: String = row["ZCONTENT"],
            let status: String = row["ZSTATUSRAWVALUE"],
            let detail: String = row["ZDETAIL"],
            let date: Double = row["ZDATE"],
            let createdAt: Double = row["ZCREATEDAT"],
            let updatedAt: Double = row["ZUPDATEDAT"],
            let owner: String = row["ZOWNER"]
      else { return nil }

      return TodoRecord(
        id: id,
        content: content,
        status: status,
        detail: detail,
        date: Date(timeIntervalSinceReferenceDate: date),
        createdAt: Date(timeIntervalSinceReferenceDate: createdAt),
        updatedAt: Date(timeIntervalSinceReferenceDate: updatedAt),
        owner: owner,
        isDeleted: (row["ZISDELETED"] as Int64? ?? 0) != 0,
      )
    }
  }

  private static func readMemos(from databaseConnection: Database) throws -> [MemoRecord] {
    try Row.fetchAll(
      databaseConnection,
      sql: """
      SELECT ZID, ZCONTENT, ZCREATEDAT, ZUPDATEDAT, ZOWNERID, ZISDELETED
      FROM ZSDMEMO
      """,
    ).compactMap { row in
      guard let id: String = row["ZID"],
            let content: String = row["ZCONTENT"],
            let createdAt: Double = row["ZCREATEDAT"],
            let updatedAt: Double = row["ZUPDATEDAT"],
            let owner: String = row["ZOWNERID"]
      else { return nil }

      return MemoRecord(
        id: id,
        content: content,
        createdAt: Date(timeIntervalSinceReferenceDate: createdAt),
        updatedAt: Date(timeIntervalSinceReferenceDate: updatedAt),
        owner: owner,
        isDeleted: (row["ZISDELETED"] as Int64? ?? 0) != 0,
      )
    }
  }
}
