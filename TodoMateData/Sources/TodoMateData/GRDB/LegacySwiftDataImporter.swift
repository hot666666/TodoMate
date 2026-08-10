import Common
import Foundation
import GRDB
import TodoMateDomain

enum LegacySwiftDataImporter {
  private static let completionKey = "legacySwiftDataImportCompleted"
  private static let generationKey = "legacySwiftDataImportGeneration"

  struct LegacyRecords {
    let todos: [TodoRecord]
    let memos: [MemoRecord]
    let rejectedRecordCount: Int
    let hasRecognizedEntityTable: Bool
  }

  struct ImportPreparation {
    var todosByID: [String: TodoRecord] = [:]
    var memosByID: [String: MemoRecord] = [:]
    var rejectedRecordCount = 0
    var unrecognizedStoreCount = 0
    var sourceReadFailed = false

    var canMarkComplete: Bool {
      !sourceReadFailed && rejectedRecordCount == 0 && unrecognizedStoreCount == 0
    }

    mutating func merge(_ records: LegacyRecords) {
      rejectedRecordCount += records.rejectedRecordCount
      if !records.hasRecognizedEntityTable {
        unrecognizedStoreCount += 1
      }
      for todo in records.todos
        where todo.updatedAt > (todosByID[todo.id]?.updatedAt ?? .distantPast) {
        todosByID[todo.id] = todo
      }
      for memo in records.memos
        where memo.updatedAt > (memosByID[memo.id]?.updatedAt ?? .distantPast) {
        memosByID[memo.id] = memo
      }
    }
  }

  static func importIfNeeded(
    from storeURLs: [URL],
    into writer: any DatabaseWriter,
  ) throws {
    guard !storeURLs.isEmpty else { return }
    guard let generation = try reserveImportGeneration(in: writer) else { return }

    let preparation = prepareImport(from: storeURLs)
    logDeferredImportReasons(in: preparation)
    try persist(preparation, generation: generation, into: writer)
  }

  static func reserveImportGeneration(in writer: any DatabaseWriter) throws -> Int64? {
    try writer.write { databaseConnection in
      guard try !isComplete(in: databaseConnection) else { return nil }
      let currentGeneration = try importGeneration(in: databaseConnection)
      guard currentGeneration < Int64.max else {
        throw LocalDatabaseError.legacyImportGenerationExhausted
      }
      let generation = currentGeneration + 1
      try databaseConnection.execute(
        sql: """
        INSERT INTO localMetadata (key, value) VALUES (?, ?)
        ON CONFLICT(key) DO UPDATE SET value = excluded.value
        """,
        arguments: [generationKey, String(generation)],
      )
      return generation
    }
  }

  static func prepareImport(from storeURLs: [URL]) -> ImportPreparation {
    var preparation = ImportPreparation()
    for url in storeURLs where FileManager.default.fileExists(atPath: url.path) {
      do {
        try preparation.merge(readLegacyStore(at: url))
      } catch {
        preparation.sourceReadFailed = true
      }
    }
    return preparation
  }

  private static func logDeferredImportReasons(in preparation: ImportPreparation) {
    if preparation.sourceReadFailed {
      Log.warning(
        "Legacy SwiftData import was deferred because a source store could not be read",
        category: .data,
      )
    }
    if preparation.rejectedRecordCount > 0 {
      Log.warning(
        "Legacy SwiftData import skipped \(preparation.rejectedRecordCount) malformed record(s); retry remains enabled",
        category: .data,
      )
    }
    if preparation.unrecognizedStoreCount > 0 {
      let message = "Legacy SwiftData import found "
        + "\(preparation.unrecognizedStoreCount) store(s) without a recognized entity table; "
        + "retry remains enabled"
      Log.warning(
        message,
        category: .data,
      )
    }
  }

  static func persist(
    _ preparation: ImportPreparation,
    generation: Int64,
    into writer: any DatabaseWriter,
  ) throws {
    try writer.write { databaseConnection in
      // Reconcile every snapshot that began before completion. A newer prepared snapshot must
      // not be discarded just because an older importer committed the marker first.
      for todo in preparation.todosByID.values {
        try LegacyImportReconciler.persist(todo, in: databaseConnection)
      }
      for memo in preparation.memosByID.values {
        try LegacyImportReconciler.persist(memo, in: databaseConnection)
      }
      guard preparation.canMarkComplete else {
        try databaseConnection.execute(
          sql: "DELETE FROM localMetadata WHERE key = ?",
          arguments: [completionKey],
        )
        return
      }
      guard try generation == importGeneration(in: databaseConnection) else { return }
      try databaseConnection.execute(
        sql: """
        INSERT INTO localMetadata (key, value) VALUES (?, ?)
        ON CONFLICT(key) DO UPDATE SET value = excluded.value
        """,
        arguments: [completionKey, "true"],
      )
    }
  }

  private static func isComplete(in databaseConnection: Database) throws -> Bool {
    try String.fetchOne(
      databaseConnection,
      sql: "SELECT value FROM localMetadata WHERE key = ?",
      arguments: [completionKey],
    ) != nil
  }

  private static func importGeneration(in databaseConnection: Database) throws -> Int64 {
    let storedValue = try String.fetchOne(
      databaseConnection,
      sql: "SELECT value FROM localMetadata WHERE key = ?",
      arguments: [generationKey],
    )
    return storedValue.flatMap(Int64.init) ?? 0
  }

  private static func readLegacyStore(at url: URL) throws -> LegacyRecords {
    var configuration = Configuration()
    configuration.readonly = true
    let database = try DatabaseQueue(path: url.path, configuration: configuration)

    return try database.read { databaseConnection in
      let hasTodoTable = try databaseConnection.tableExists("ZSDTODO")
      let hasMemoTable = try databaseConnection.tableExists("ZSDMEMO")
      let todoResult = hasTodoTable
        ? try readTodos(from: databaseConnection) : (records: [], rejectedRecordCount: 0)
      let memoResult = hasMemoTable
        ? try readMemos(from: databaseConnection) : (records: [], rejectedRecordCount: 0)
      return LegacyRecords(
        todos: todoResult.records,
        memos: memoResult.records,
        rejectedRecordCount: todoResult.rejectedRecordCount + memoResult.rejectedRecordCount,
        hasRecognizedEntityTable: hasTodoTable || hasMemoTable,
      )
    }
  }

  private static func readTodos(from databaseConnection: Database) throws -> (
    records: [TodoRecord],
    rejectedRecordCount: Int,
  ) {
    let rows = try Row.fetchAll(
      databaseConnection,
      sql: """
      SELECT ZID, ZCONTENT, ZSTATUSRAWVALUE, ZDETAIL, ZDATE, ZCREATEDAT,
             ZUPDATEDAT, ZOWNER, ZISDELETED
      FROM ZSDTODO
      """,
    )
    var records: [TodoRecord] = []
    var rejectedRecordCount = 0

    for row in rows {
      guard let id: String = row["ZID"],
            let content: String = row["ZCONTENT"],
            let statusValue: String = row["ZSTATUSRAWVALUE"],
            let detail: String = row["ZDETAIL"],
            let date: Double = row["ZDATE"],
            let createdAt: Double = row["ZCREATEDAT"],
            let updatedAt: Double = row["ZUPDATEDAT"],
            let owner: String = row["ZOWNER"],
            date.isFinite,
            createdAt.isFinite,
            updatedAt.isFinite
      else {
        rejectedRecordCount += 1
        continue
      }
      // Match the legacy SwiftData decoder: unknown historical values remain usable as `.todo`.
      let status = TodoStatus(rawValue: statusValue) ?? .todo

      let modificationDate = Date(timeIntervalSinceReferenceDate: updatedAt)

      records.append(TodoRecord(
        id: id,
        content: content,
        status: status,
        detail: detail,
        date: Date(timeIntervalSinceReferenceDate: date),
        createdAt: Date(timeIntervalSinceReferenceDate: createdAt),
        updatedAt: modificationDate,
        ownerID: LocalAuthorID.canonicalizing(owner),
        deletedAt: (row["ZISDELETED"] as Int64? ?? 0) != 0 ? modificationDate : nil,
      ))
    }

    return (records, rejectedRecordCount)
  }

  private static func readMemos(from databaseConnection: Database) throws -> (
    records: [MemoRecord],
    rejectedRecordCount: Int,
  ) {
    let rows = try Row.fetchAll(
      databaseConnection,
      sql: """
      SELECT ZID, ZCONTENT, ZCREATEDAT, ZUPDATEDAT, ZOWNERID, ZISDELETED
      FROM ZSDMEMO
      """,
    )
    var records: [MemoRecord] = []
    var rejectedRecordCount = 0

    for row in rows {
      guard let id: String = row["ZID"],
            let content: String = row["ZCONTENT"],
            let createdAt: Double = row["ZCREATEDAT"],
            let updatedAt: Double = row["ZUPDATEDAT"],
            let owner: String = row["ZOWNERID"],
            createdAt.isFinite,
            updatedAt.isFinite
      else {
        rejectedRecordCount += 1
        continue
      }

      let modificationDate = Date(timeIntervalSinceReferenceDate: updatedAt)

      records.append(MemoRecord(
        id: id,
        content: content,
        createdAt: Date(timeIntervalSinceReferenceDate: createdAt),
        updatedAt: modificationDate,
        ownerID: LocalAuthorID.canonicalizing(owner),
        deletedAt: (row["ZISDELETED"] as Int64? ?? 0) != 0 ? modificationDate : nil,
      ))
    }

    return (records, rejectedRecordCount)
  }
}

private enum LegacyImportReconciler {
  private enum EntityKind: String {
    case todo
    case memo
  }

  private struct Provenance: Codable {
    let sourceUpdatedAt: Double
    let appliedLocalRevision: Int64
  }

  private static let provenanceKeyPrefix = "legacySwiftDataImport.provenance.v1"

  static func persist(_ incoming: TodoRecord, in databaseConnection: Database) throws {
    let key = provenanceKey(for: .todo, id: incoming.id)
    let storedProvenance = try String.fetchOne(
      databaseConnection,
      sql: "SELECT value FROM localMetadata WHERE key = ?",
      arguments: [key],
    )

    guard let current = try TodoRecord.fetchOne(databaseConnection, key: incoming.id) else {
      guard storedProvenance == nil else { return }
      try incoming.insert(databaseConnection)
      try saveProvenance(for: incoming, key: key, in: databaseConnection)
      return
    }

    guard let provenance = decode(storedProvenance),
          current.localRevision == provenance.appliedLocalRevision,
          current.updatedAt.timeIntervalSinceReferenceDate == provenance.sourceUpdatedAt,
          incoming.updatedAt.timeIntervalSinceReferenceDate > provenance.sourceUpdatedAt,
          current.localRevision < Int64.max
    else { return }

    var replacement = incoming
    replacement.localRevision = current.localRevision + 1
    try replacement.update(databaseConnection)
    try saveProvenance(for: replacement, key: key, in: databaseConnection)
  }

  static func persist(_ incoming: MemoRecord, in databaseConnection: Database) throws {
    let key = provenanceKey(for: .memo, id: incoming.id)
    let storedProvenance = try String.fetchOne(
      databaseConnection,
      sql: "SELECT value FROM localMetadata WHERE key = ?",
      arguments: [key],
    )

    guard let current = try MemoRecord.fetchOne(databaseConnection, key: incoming.id) else {
      guard storedProvenance == nil else { return }
      try incoming.insert(databaseConnection)
      try saveProvenance(for: incoming, key: key, in: databaseConnection)
      return
    }

    guard let provenance = decode(storedProvenance),
          current.localRevision == provenance.appliedLocalRevision,
          current.updatedAt.timeIntervalSinceReferenceDate == provenance.sourceUpdatedAt,
          incoming.updatedAt.timeIntervalSinceReferenceDate > provenance.sourceUpdatedAt,
          current.localRevision < Int64.max
    else { return }

    var replacement = incoming
    replacement.localRevision = current.localRevision + 1
    try replacement.update(databaseConnection)
    try saveProvenance(for: replacement, key: key, in: databaseConnection)
  }

  private static func provenanceKey(for kind: EntityKind, id: String) -> String {
    "\(provenanceKeyPrefix).\(kind.rawValue).\(id)"
  }

  private static func decode(_ storedValue: String?) -> Provenance? {
    guard let storedValue, let data = Data(base64Encoded: storedValue) else { return nil }
    return try? JSONDecoder().decode(Provenance.self, from: data)
  }

  private static func saveProvenance(
    for record: TodoRecord,
    key: String,
    in databaseConnection: Database,
  ) throws {
    try saveProvenance(
      Provenance(
        sourceUpdatedAt: record.updatedAt.timeIntervalSinceReferenceDate,
        appliedLocalRevision: record.localRevision,
      ),
      key: key,
      in: databaseConnection,
    )
  }

  private static func saveProvenance(
    for record: MemoRecord,
    key: String,
    in databaseConnection: Database,
  ) throws {
    try saveProvenance(
      Provenance(
        sourceUpdatedAt: record.updatedAt.timeIntervalSinceReferenceDate,
        appliedLocalRevision: record.localRevision,
      ),
      key: key,
      in: databaseConnection,
    )
  }

  private static func saveProvenance(
    _ provenance: Provenance,
    key: String,
    in databaseConnection: Database,
  ) throws {
    let data = try JSONEncoder().encode(provenance)
    try databaseConnection.execute(
      sql: """
      INSERT INTO localMetadata (key, value) VALUES (?, ?)
      ON CONFLICT(key) DO UPDATE SET value = excluded.value
      """,
      arguments: [key, data.base64EncodedString()],
    )
  }
}
