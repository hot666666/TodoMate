import Foundation
import GRDB
import Testing
@testable import TodoMateData
import TodoMateDomain

@Suite("Legacy SwiftData Import Reconciliation Tests", .serialized)
struct LegacyImportRaceTests {
  @Test("Reconciles a newer snapshot prepared before an older import completed")
  func reconcilesPreparedSnapshotRace() async throws {
    let olderURL = LegacyImportBehaviorTests.temporaryStoreURL(label: "prepared-older")
    let newerURL = LegacyImportBehaviorTests.temporaryStoreURL(label: "prepared-newer")
    defer {
      LegacyImportBehaviorTests.removeDatabaseFiles(at: olderURL)
      LegacyImportBehaviorTests.removeDatabaseFiles(at: newerURL)
    }

    try await LegacyImportBehaviorTests.createLegacyStore(
      at: olderURL,
      timestamp: Date(timeIntervalSinceReferenceDate: 100),
      todoContent: "Older Todo",
      memoContent: "Older Memo",
    )
    try await LegacyImportBehaviorTests.createLegacyStore(
      at: newerURL,
      timestamp: Date(timeIntervalSinceReferenceDate: 200),
      todoContent: "Newer Todo",
      memoContent: "Newer Memo",
    )

    let database = try GRDBDatabase(storage: .inMemory)
    let olderGeneration = try #require(
      try LegacySwiftDataImporter.reserveImportGeneration(in: database.writer),
    )
    let olderPreparation = LegacySwiftDataImporter.prepareImport(from: [olderURL])
    let newerGeneration = try #require(
      try LegacySwiftDataImporter.reserveImportGeneration(in: database.writer),
    )
    let newerPreparation = LegacySwiftDataImporter.prepareImport(from: [newerURL])

    try LegacySwiftDataImporter.persist(
      olderPreparation,
      generation: olderGeneration,
      into: database.writer,
    )
    try LegacySwiftDataImporter.persist(
      newerPreparation,
      generation: newerGeneration,
      into: database.writer,
    )

    let records = try await LegacyImportBehaviorTests.records(in: database)
    #expect(records.todo?.content == "Newer Todo")
    #expect(records.todo?.localRevision == 2)
    #expect(records.memo?.content == "Newer Memo")
    #expect(records.memo?.localRevision == 2)
    #expect(try await LegacyImportBehaviorTests.importCompletion(in: database) == "true")
  }

  @Test("A stale complete snapshot cannot close a newer incomplete import")
  func staleCompleteSnapshotCannotCloseNewerIncompleteImport() async throws {
    let olderURL = LegacyImportBehaviorTests.temporaryStoreURL(label: "complete-older")
    let newerURL = LegacyImportBehaviorTests.temporaryStoreURL(label: "incomplete-newer")
    defer {
      LegacyImportBehaviorTests.removeDatabaseFiles(at: olderURL)
      LegacyImportBehaviorTests.removeDatabaseFiles(at: newerURL)
    }

    try await LegacyImportBehaviorTests.createLegacyStore(
      at: olderURL,
      timestamp: Date(timeIntervalSinceReferenceDate: 100),
      todoContent: "Older Todo",
      memoContent: "Older Memo",
    )
    try await LegacyImportBehaviorTests.createLegacyStore(
      at: newerURL,
      timestamp: Date(timeIntervalSinceReferenceDate: 200),
      todoContent: "Newer Todo",
      memoContent: "Newer Memo",
    )
    try await LegacyImportBehaviorTests.setMemoContentToNull(at: newerURL)

    let database = try GRDBDatabase(storage: .inMemory)
    let olderGeneration = try #require(
      try LegacySwiftDataImporter.reserveImportGeneration(in: database.writer),
    )
    let olderPreparation = LegacySwiftDataImporter.prepareImport(from: [olderURL])
    let newerGeneration = try #require(
      try LegacySwiftDataImporter.reserveImportGeneration(in: database.writer),
    )
    let newerPreparation = LegacySwiftDataImporter.prepareImport(from: [newerURL])

    try LegacySwiftDataImporter.persist(
      newerPreparation,
      generation: newerGeneration,
      into: database.writer,
    )
    try LegacySwiftDataImporter.persist(
      olderPreparation,
      generation: olderGeneration,
      into: database.writer,
    )

    #expect(try await LegacyImportBehaviorTests.importCompletion(in: database) == nil)
    try await LegacyImportBehaviorTests.repairMemoContent(at: newerURL, content: "Newer Memo")
    try LegacySwiftDataImporter.importIfNeeded(
      from: [olderURL, newerURL],
      into: database.writer,
    )

    let records = try await LegacyImportBehaviorTests.records(in: database)
    #expect(records.todo?.content == "Newer Todo")
    #expect(records.memo?.content == "Newer Memo")
    #expect(try await LegacyImportBehaviorTests.importCompletion(in: database) == "true")
  }

  @Test("A delayed stale generation can reopen completion with an incomplete snapshot")
  func delayedStaleGenerationCanReopenIncompleteImport() async throws {
    let legacyURL = LegacyImportBehaviorTests.temporaryStoreURL(label: "delayed-incomplete")
    defer { LegacyImportBehaviorTests.removeDatabaseFiles(at: legacyURL) }
    try await LegacyImportBehaviorTests.createLegacyStore(
      at: legacyURL,
      timestamp: Date(timeIntervalSinceReferenceDate: 100),
      todoContent: "Todo",
      memoContent: "Memo",
    )

    let database = try GRDBDatabase(storage: .inMemory)
    let stalledGeneration = try #require(
      try LegacySwiftDataImporter.reserveImportGeneration(in: database.writer),
    )
    let latestGeneration = try #require(
      try LegacySwiftDataImporter.reserveImportGeneration(in: database.writer),
    )
    let latestPreparation = LegacySwiftDataImporter.prepareImport(from: [legacyURL])
    try LegacySwiftDataImporter.persist(
      latestPreparation,
      generation: latestGeneration,
      into: database.writer,
    )
    #expect(try await LegacyImportBehaviorTests.importCompletion(in: database) == "true")

    try await LegacyImportBehaviorTests.setMemoContentToNull(at: legacyURL)
    let delayedIncompletePreparation = LegacySwiftDataImporter.prepareImport(from: [legacyURL])
    try LegacySwiftDataImporter.persist(
      delayedIncompletePreparation,
      generation: stalledGeneration,
      into: database.writer,
    )
    #expect(try await LegacyImportBehaviorTests.importCompletion(in: database) == nil)

    try await LegacyImportBehaviorTests.repairMemoContent(at: legacyURL, content: "Memo")
    try LegacySwiftDataImporter.importIfNeeded(from: [legacyURL], into: database.writer)
    #expect(try await LegacyImportBehaviorTests.importCompletion(in: database) == "true")
  }
}

@Suite("Legacy SwiftData Import Behavior Tests", .serialized)
struct LegacyImportBehaviorTests {
  @Test("Refreshes untouched partial imports from a newer repaired source")
  func refreshesUntouchedPartialImports() async throws {
    let olderURL = Self.temporaryStoreURL(label: "older")
    let newerURL = Self.temporaryStoreURL(label: "newer")
    defer {
      Self.removeDatabaseFiles(at: olderURL)
      Self.removeDatabaseFiles(at: newerURL)
    }

    try await Self.createLegacyStore(
      at: olderURL,
      timestamp: Date(timeIntervalSinceReferenceDate: 100),
      todoContent: "Older Todo",
      memoContent: "Older Memo",
    )
    try await Self.createLegacyStore(
      at: newerURL,
      timestamp: Date(timeIntervalSinceReferenceDate: 200),
      todoContent: "Newer Todo",
      memoContent: "Newer Memo",
    )
    try await Self.setContentToNull(at: newerURL)

    let database = try GRDBDatabase(storage: .inMemory)
    try LegacySwiftDataImporter.importIfNeeded(
      from: [olderURL, newerURL],
      into: database.writer,
    )

    let partialRecords = try await Self.records(in: database)
    #expect(partialRecords.todo?.content == "Older Todo")
    #expect(partialRecords.todo?.localRevision == 1)
    #expect(partialRecords.memo?.content == "Older Memo")
    #expect(partialRecords.memo?.localRevision == 1)
    #expect(try await Self.importCompletion(in: database) == nil)

    try await Self.repairContent(at: newerURL)
    try LegacySwiftDataImporter.importIfNeeded(
      from: [olderURL, newerURL],
      into: database.writer,
    )

    let refreshedRecords = try await Self.records(in: database)
    #expect(refreshedRecords.todo?.content == "Newer Todo")
    #expect(refreshedRecords.todo?.localRevision == 2)
    #expect(refreshedRecords.memo?.content == "Newer Memo")
    #expect(refreshedRecords.memo?.localRevision == 2)
    #expect(try await Self.importCompletion(in: database) == "true")

    try LegacySwiftDataImporter.importIfNeeded(
      from: [olderURL, newerURL],
      into: database.writer,
    )
    let finalRecords = try await Self.records(in: database)
    #expect(finalRecords.todo?.localRevision == 2)
    #expect(finalRecords.memo?.localRevision == 2)
  }

  @Test("Preserves a pre-existing local row without import provenance")
  func preservesPreExistingLocalRow() async throws {
    let legacyURL = Self.temporaryStoreURL(label: "collision")
    defer { Self.removeDatabaseFiles(at: legacyURL) }
    try await Self.createLegacyStore(
      at: legacyURL,
      timestamp: Date(timeIntervalSinceReferenceDate: 200),
      todoContent: "Legacy Todo",
      memoContent: "Legacy Memo",
    )

    let database = try GRDBDatabase(storage: .inMemory)
    let localRecord = TodoRecord(
      id: "todo-id",
      content: "Local Todo",
      status: .todo,
      detail: "",
      date: .distantPast,
      createdAt: .distantPast,
      updatedAt: .distantPast,
      ownerID: "owner",
      deletedAt: nil,
    )
    try await database.writer.write { databaseConnection in
      try localRecord.insert(databaseConnection)
    }

    try LegacySwiftDataImporter.importIfNeeded(from: [legacyURL], into: database.writer)

    let records = try await Self.records(in: database)
    #expect(records.todo?.content == "Local Todo")
    #expect(records.todo?.localRevision == 1)
    #expect(records.memo?.content == "Legacy Memo")
    #expect(try await Self.importCompletion(in: database) == "true")
  }

  @Test("Does not resurrect a partially imported row after permanent deletion")
  func doesNotResurrectPermanentlyDeletedRow() async throws {
    let legacyURL = Self.temporaryStoreURL(label: "deleted")
    defer { Self.removeDatabaseFiles(at: legacyURL) }
    try await Self.createLegacyStore(
      at: legacyURL,
      timestamp: Date(timeIntervalSinceReferenceDate: 100),
      todoContent: "Imported Todo",
      memoContent: "Imported Memo",
    )
    try await Self.setMemoContentToNull(at: legacyURL)

    let database = try GRDBDatabase(storage: .inMemory)
    try LegacySwiftDataImporter.importIfNeeded(from: [legacyURL], into: database.writer)
    let importedTodo = try #require(try await Self.records(in: database).todo)

    let deletedItemsRepository = GRDBDeletedItemsRepository(database: database)
    try await deletedItemsRepository.permanentlyDelete(.todo(importedTodo.domainValue()))
    #expect(try await Self.records(in: database).todo == nil)

    try await Self.repairMemoContent(at: legacyURL, content: "Imported Memo")
    try LegacySwiftDataImporter.importIfNeeded(from: [legacyURL], into: database.writer)

    let finalRecords = try await Self.records(in: database)
    #expect(finalRecords.todo == nil)
    #expect(finalRecords.memo?.content == "Imported Memo")
    #expect(try await Self.importCompletion(in: database) == "true")
  }

  fileprivate static func records(in database: GRDBDatabase) async throws -> (
    todo: TodoRecord?,
    memo: MemoRecord?,
  ) {
    try await database.writer.read { databaseConnection in
      try (
        TodoRecord.fetchOne(databaseConnection, key: "todo-id"),
        MemoRecord.fetchOne(databaseConnection, key: "memo-id"),
      )
    }
  }

  fileprivate static func importCompletion(in database: GRDBDatabase) async throws -> String? {
    try await database.writer.read { databaseConnection in
      try String.fetchOne(
        databaseConnection,
        sql: "SELECT value FROM localMetadata WHERE key = ?",
        arguments: ["legacySwiftDataImportCompleted"],
      )
    }
  }

  fileprivate static func temporaryStoreURL(label: String) -> URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent("legacy-\(label)-\(UUID().uuidString).store")
  }

  fileprivate static func createLegacyStore(
    at url: URL,
    timestamp: Date,
    todoContent: String,
    memoContent: String,
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
      let legacyTimestamp = timestamp.timeIntervalSinceReferenceDate
      try databaseConnection.execute(
        sql: "INSERT INTO ZSDTODO VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
        arguments: [
          "todo-id", todoContent, "시작 전", "detail", legacyTimestamp,
          legacyTimestamp, legacyTimestamp, "owner", 0,
        ],
      )
      try databaseConnection.execute(
        sql: "INSERT INTO ZSDMEMO VALUES (?, ?, ?, ?, ?, ?)",
        arguments: [
          "memo-id", memoContent, legacyTimestamp, legacyTimestamp, "owner", 0,
        ],
      )
    }
  }

  fileprivate static func setContentToNull(at url: URL) async throws {
    let database = try DatabaseQueue(path: url.path)
    try await database.write { databaseConnection in
      try databaseConnection.execute(sql: "UPDATE ZSDTODO SET ZCONTENT = NULL")
      try databaseConnection.execute(sql: "UPDATE ZSDMEMO SET ZCONTENT = NULL")
    }
  }

  fileprivate static func setMemoContentToNull(at url: URL) async throws {
    let database = try DatabaseQueue(path: url.path)
    try await database.write { databaseConnection in
      try databaseConnection.execute(sql: "UPDATE ZSDMEMO SET ZCONTENT = NULL")
    }
  }

  fileprivate static func repairContent(at url: URL) async throws {
    let database = try DatabaseQueue(path: url.path)
    try await database.write { databaseConnection in
      try databaseConnection.execute(
        sql: "UPDATE ZSDTODO SET ZCONTENT = ?",
        arguments: ["Newer Todo"],
      )
      try databaseConnection.execute(
        sql: "UPDATE ZSDMEMO SET ZCONTENT = ?",
        arguments: ["Newer Memo"],
      )
    }
  }

  fileprivate static func repairMemoContent(at url: URL, content: String) async throws {
    let database = try DatabaseQueue(path: url.path)
    try await database.write { databaseConnection in
      try databaseConnection.execute(
        sql: "UPDATE ZSDMEMO SET ZCONTENT = ?",
        arguments: [content],
      )
    }
  }

  fileprivate static func removeDatabaseFiles(at url: URL) {
    try? FileManager.default.removeItem(at: url)
    try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + "-wal"))
    try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + "-shm"))
  }
}
