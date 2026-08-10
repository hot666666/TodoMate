import Common
import Darwin
import Foundation
import GRDB
import Synchronization

enum GRDBAppGroupMigrationOutcome: Equatable, Sendable {
  case noLegacyDatabase
  case migrated
  case alreadyMigrated
}

enum GRDBAppGroupMigrationError: Error, Equatable {
  case destinationExistsWithoutValidMarker(URL)
  case invalidDatabase(URL)
  case legacySourceChangedAfterMigration(URL)
  case projectionMismatch
  case lockOpenFailed(URL, Int32)
  case lockFailed(URL, Int32)
  case atomicPromotionFailed(URL, Int32)
  case stagingDatabaseHasSidecars(URL)
}

struct GRDBSharedDatabaseLocations: Equatable, Sendable {
  let databaseURL: URL
  let legacyDatabaseURL: URL
  let legacyStoreURLs: [URL]
}

struct GRDBAppGroupContainerResolution: Equatable, Sendable {
  let groupURL: URL?
  let legacyGroupURL: URL?
}

enum GRDBAppGroupStorage {
  static func locations(fileManager: FileManager = .default) throws -> GRDBSharedDatabaseLocations {
    try locations(
      resolution: GRDBAppGroupContainerResolution(
        groupURL: fileManager.containerURL(
          forSecurityApplicationGroupIdentifier: AppEnvironment.Container.appGroupIdentifier,
        ),
        legacyGroupURL: fileManager.containerURL(
          forSecurityApplicationGroupIdentifier: AppEnvironment.Container.legacyAppGroupIdentifier,
        ),
      ),
    )
  }

  static func locations(
    resolution: GRDBAppGroupContainerResolution,
  ) throws -> GRDBSharedDatabaseLocations {
    guard let groupURL = resolution.groupURL else {
      throw LocalDatabaseError.appGroupContainerUnavailable(
        AppEnvironment.Container.appGroupIdentifier,
      )
    }
    guard let legacyGroupURL = resolution.legacyGroupURL else {
      throw LocalDatabaseError.appGroupContainerUnavailable(
        AppEnvironment.Container.legacyAppGroupIdentifier,
      )
    }
    return locations(groupURL: groupURL, legacyGroupURL: legacyGroupURL)
  }

  static func readOnlyLocations(
    fileManager: FileManager = .default,
  ) -> GRDBSharedDatabaseLocations? {
    readOnlyLocations(
      resolution: GRDBAppGroupContainerResolution(
        groupURL: fileManager.containerURL(
          forSecurityApplicationGroupIdentifier: AppEnvironment.Container.appGroupIdentifier,
        ),
        legacyGroupURL: fileManager.containerURL(
          forSecurityApplicationGroupIdentifier: AppEnvironment.Container.legacyAppGroupIdentifier,
        ),
      ),
    )
  }

  static func readOnlyLocations(
    resolution: GRDBAppGroupContainerResolution,
  ) -> GRDBSharedDatabaseLocations? {
    guard let groupURL = resolution.groupURL,
      let legacyGroupURL = resolution.legacyGroupURL
    else { return nil }
    return locations(groupURL: groupURL, legacyGroupURL: legacyGroupURL)
  }

  static func locations(
    groupURL: URL,
    legacyGroupURL: URL,
  ) -> GRDBSharedDatabaseLocations {
    let storeURLs =
      legacyStoreURLs(in: groupURL)
      + legacyStoreURLs(in: legacyGroupURL)
    return GRDBSharedDatabaseLocations(
      databaseURL: databaseURL(in: groupURL),
      legacyDatabaseURL: databaseURL(in: legacyGroupURL),
      legacyStoreURLs: storeURLs,
    )
  }

  static func databaseURL(in groupURL: URL) -> URL {
    groupURL
      .appendingPathComponent("Library/Application Support", isDirectory: true)
      .appendingPathComponent(AppEnvironment.Container.name, isDirectory: true)
      .appendingPathComponent("TodoMate.sqlite")
  }

  private static func legacyStoreURLs(in groupURL: URL) -> [URL] {
    let supportURL = groupURL.appendingPathComponent(
      "Library/Application Support",
      isDirectory: true,
    )
    return [
      supportURL.appendingPathComponent("\(AppEnvironment.Container.name).store"),
      supportURL.appendingPathComponent("default.store"),
      groupURL.appendingPathComponent("default.store"),
    ]
  }
}

enum GRDBAppGroupMigration {
  private static let markerKey = "appGroupContainerMigration.v1"
  private static let markerVersion = 1
  private static let stagingNamePrefix = ".TodoMate.sqlite.app-group-migration-"
  private static let inProcessMigrationLock = Mutex(())

  static func migrateIfNeeded(
    from legacyDatabaseURL: URL,
    to databaseURL: URL,
    fileManager: FileManager = .default,
  ) throws -> GRDBAppGroupMigrationOutcome {
    guard legacyDatabaseURL.standardizedFileURL != databaseURL.standardizedFileURL else {
      return .noLegacyDatabase
    }

    let directoryURL = databaseURL.deletingLastPathComponent()
    return try inProcessMigrationLock.withLock { _ in
      let legacyDatabaseExists = fileManager.fileExists(atPath: legacyDatabaseURL.path)
      let destinationDirectoryExists = fileManager.fileExists(atPath: directoryURL.path)
      guard legacyDatabaseExists || destinationDirectoryExists else {
        return .noLegacyDatabase
      }

      if !destinationDirectoryExists {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
      }
      let lockURL = directoryURL.appendingPathComponent(
        ".TodoMate.app-group-migration-v1.lock",
      )

      return try withExclusiveLock(at: lockURL) {
        try removeOrphanedStagingFiles(in: directoryURL, fileManager: fileManager)
        guard fileManager.fileExists(atPath: legacyDatabaseURL.path) else {
          if fileManager.fileExists(atPath: databaseURL.path),
            validMigrationMarker(at: databaseURL) != nil
          {
            throw GRDBAppGroupMigrationError.legacySourceChangedAfterMigration(
              legacyDatabaseURL,
            )
          }
          return .noLegacyDatabase
        }

        if fileManager.fileExists(atPath: databaseURL.path) {
          guard let marker = validMigrationMarker(at: databaseURL) else {
            throw GRDBAppGroupMigrationError.destinationExistsWithoutValidMarker(databaseURL)
          }
          let currentSourceSignature = try legacySourceSignature(at: legacyDatabaseURL)
          guard currentSourceSignature == marker.sourceProjection else {
            throw GRDBAppGroupMigrationError.legacySourceChangedAfterMigration(
              legacyDatabaseURL,
            )
          }
          return .alreadyMigrated
        }

        let stagingURL = directoryURL.appendingPathComponent(
          "\(stagingNamePrefix)\(UUID().uuidString).tmp",
        )
        defer { removeSQLiteFiles(at: stagingURL, fileManager: fileManager) }

        let source = try makeReadOnlyPool(at: legacyDatabaseURL)
        let sourceSnapshot: ProjectionSnapshot

        do {
          let staging = try DatabaseQueue(path: stagingURL.path)
          try source.backup(to: staging)
          sourceSnapshot = try validatedProjection(in: staging, at: stagingURL)

          try GRDBDatabase.migrator.migrate(staging)
          let migratedSnapshot = try validatedCurrentProjection(in: staging, at: stagingURL)
          guard sourceSnapshot == migratedSnapshot else {
            throw GRDBAppGroupMigrationError.projectionMismatch
          }

          let marker = MigrationMarker(
            version: markerVersion,
            sourceProjection: try migratedSnapshot.signature(),
          )
          try write(marker: marker, to: staging)
          guard try readMarker(from: staging) == marker else {
            throw GRDBAppGroupMigrationError.invalidDatabase(stagingURL)
          }
          _ = try validatedCurrentProjection(in: staging, at: stagingURL)
          try sealForSingleFilePromotion(staging, at: stagingURL)
        }

        try removeSealedWALSidecars(at: stagingURL, fileManager: fileManager)
        guard !sqliteSidecarsExist(at: stagingURL, fileManager: fileManager) else {
          throw GRDBAppGroupMigrationError.stagingDatabaseHasSidecars(stagingURL)
        }
        try promoteExclusively(from: stagingURL, to: databaseURL)
        return .migrated
      }
    }
  }

  static func preferredReadOnlyDatabaseURL(
    databaseURL: URL,
    legacyDatabaseURL: URL,
    fileManager: FileManager = .default,
  ) -> URL? {
    let legacyExists = fileManager.fileExists(atPath: legacyDatabaseURL.path)
    if let marker = validMigrationMarker(at: databaseURL) {
      guard legacyExists,
        legacySourceMatches(
          marker: marker,
          legacyDatabaseURL: legacyDatabaseURL,
        )
      else { return nil }

      if databaseIsReady(at: databaseURL, fileManager: fileManager) {
        return databaseURL
      }
      return databaseIsReady(at: legacyDatabaseURL, fileManager: fileManager)
        ? legacyDatabaseURL : nil
    }

    if !legacyExists, databaseIsReady(at: databaseURL, fileManager: fileManager) {
      return databaseURL
    }
    if databaseIsReady(at: legacyDatabaseURL, fileManager: fileManager) {
      return legacyDatabaseURL
    }
    return nil
  }

  private static func validMigrationMarker(at databaseURL: URL) -> MigrationMarker? {
    do {
      let reader = try makeReadOnlyPool(at: databaseURL)
      guard try databaseQuickCheckPasses(in: reader),
        let marker = try readMarker(from: reader),
        marker.version == markerVersion
      else { return nil }
      return marker
    } catch {
      return nil
    }
  }

  private static func legacySourceMatches(
    marker: MigrationMarker,
    legacyDatabaseURL: URL,
  ) -> Bool {
    do {
      return try legacySourceSignature(at: legacyDatabaseURL) == marker.sourceProjection
    } catch {
      return false
    }
  }

  private static func legacySourceSignature(at databaseURL: URL) throws -> ProjectionSignature {
    let reader = try makeReadOnlyPool(at: databaseURL)
    return try validatedProjection(in: reader, at: databaseURL).signature()
  }

  private static func databaseIsReady(
    at databaseURL: URL,
    fileManager: FileManager,
  ) -> Bool {
    guard fileManager.fileExists(atPath: databaseURL.path) else { return false }
    do {
      let reader = try makeReadOnlyPool(at: databaseURL)
      _ = try validatedCurrentProjection(in: reader, at: databaseURL)
      return true
    } catch {
      return false
    }
  }

  private static func makeReadOnlyPool(at databaseURL: URL) throws -> DatabasePool {
    var configuration = Configuration()
    configuration.readonly = true
    configuration.busyMode = .timeout(5)
    return try DatabasePool(path: databaseURL.path, configuration: configuration)
  }

  private static func validatedCurrentProjection(
    in reader: any DatabaseReader,
    at databaseURL: URL,
  ) throws -> ProjectionSnapshot {
    guard try databaseQuickCheckPasses(in: reader) else {
      throw GRDBAppGroupMigrationError.invalidDatabase(databaseURL)
    }
    let hasCurrentSchema = try reader.read { databaseConnection in
      let migrator = GRDBDatabase.migrator
      return try !migrator.hasBeenSuperseded(databaseConnection)
        && migrator.hasCompletedMigrations(databaseConnection)
    }
    guard hasCurrentSchema else {
      throw GRDBAppGroupMigrationError.invalidDatabase(databaseURL)
    }
    return try projection(in: reader)
  }

  private static func validatedProjection(
    in reader: any DatabaseReader,
    at databaseURL: URL,
  ) throws -> ProjectionSnapshot {
    guard try databaseQuickCheckPasses(in: reader) else {
      throw GRDBAppGroupMigrationError.invalidDatabase(databaseURL)
    }
    return try projection(in: reader)
  }

  private static func databaseQuickCheckPasses(in reader: any DatabaseReader) throws -> Bool {
    try reader.read { databaseConnection in
      try String.fetchAll(databaseConnection, sql: "PRAGMA quick_check") == ["ok"]
    }
  }

  private static func projection(in reader: any DatabaseReader) throws -> ProjectionSnapshot {
    try reader.read { databaseConnection in
      let todoColumns = try Set(
        databaseConnection.columns(in: TodoRecord.databaseTableName).map(\.name),
      )
      let memoColumns = try Set(
        databaseConnection.columns(in: MemoRecord.databaseTableName).map(\.name),
      )
      guard todoColumns.contains("id"),
        todoColumns.contains("content"),
        todoColumns.contains("status"),
        todoColumns.contains("detail"),
        todoColumns.contains("date"),
        todoColumns.contains("createdAt"),
        todoColumns.contains("updatedAt"),
        todoColumns.contains("ownerId") || todoColumns.contains("owner"),
        memoColumns.contains("id"),
        memoColumns.contains("content"),
        memoColumns.contains("createdAt"),
        memoColumns.contains("updatedAt"),
        memoColumns.contains("ownerId") || memoColumns.contains("owner")
      else {
        throw GRDBAppGroupMigrationError.projectionMismatch
      }

      let todoOwnerColumn = todoColumns.contains("ownerId") ? "ownerId" : "owner"
      let todoDeletedExpression =
        todoColumns.contains("deletedAt")
        ? "deletedAt"
        : "CASE WHEN isDeleted = 1 THEN updatedAt ELSE NULL END"
      let todoRevisionExpression =
        todoColumns.contains("localRevision")
        ? "localRevision"
        : "1"
      let memoOwnerColumn = memoColumns.contains("ownerId") ? "ownerId" : "owner"
      let memoDeletedExpression =
        memoColumns.contains("deletedAt")
        ? "deletedAt"
        : "CASE WHEN isDeleted = 1 THEN updatedAt ELSE NULL END"
      let memoRevisionExpression =
        memoColumns.contains("localRevision")
        ? "localRevision"
        : "1"

      let todoRows = try Row.fetchAll(
        databaseConnection,
        sql: """
          SELECT id, content, status, detail, date, createdAt, updatedAt,
                 \(todoOwnerColumn) AS ownerId,
                 \(todoDeletedExpression) AS deletedAt,
                 \(todoRevisionExpression) AS localRevision
          FROM todo
          ORDER BY id
          """,
      )
      let memoRows = try Row.fetchAll(
        databaseConnection,
        sql: """
          SELECT id, content, createdAt, updatedAt,
                 \(memoOwnerColumn) AS ownerId,
                 \(memoDeletedExpression) AS deletedAt,
                 \(memoRevisionExpression) AS localRevision
          FROM memo
          ORDER BY id
          """,
      )

      return ProjectionSnapshot(
        todos: todoRows.map(TodoProjection.init(row:)),
        memos: memoRows.map(MemoProjection.init(row:)),
      )
    }
  }

  private static func write(marker: MigrationMarker, to writer: any DatabaseWriter) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let value = String(decoding: try encoder.encode(marker), as: UTF8.self)
    try writer.write { databaseConnection in
      try databaseConnection.execute(
        sql: """
          INSERT INTO localMetadata (key, value) VALUES (?, ?)
          ON CONFLICT(key) DO UPDATE SET value = excluded.value
          """,
        arguments: [markerKey, value],
      )
    }
  }

  private static func sealForSingleFilePromotion(
    _ writer: any DatabaseWriter,
    at databaseURL: URL,
  ) throws {
    let journalMode = try writer.writeWithoutTransaction { databaseConnection in
      try databaseConnection.execute(sql: "PRAGMA wal_checkpoint(TRUNCATE)")
      return try String.fetchOne(databaseConnection, sql: "PRAGMA journal_mode = DELETE")
    }
    guard journalMode?.lowercased() == "delete" else {
      throw GRDBAppGroupMigrationError.invalidDatabase(databaseURL)
    }
  }

  private static func readMarker(from reader: any DatabaseReader) throws -> MigrationMarker? {
    try reader.read { databaseConnection in
      guard try databaseConnection.tableExists("localMetadata"),
        let value = try String.fetchOne(
          databaseConnection,
          sql: "SELECT value FROM localMetadata WHERE key = ?",
          arguments: [markerKey],
        ),
        let data = value.data(using: .utf8)
      else {
        return nil
      }
      return try? JSONDecoder().decode(MigrationMarker.self, from: data)
    }
  }

  private static func withExclusiveLock<Result>(
    at lockURL: URL,
    _ operation: () throws -> Result,
  ) throws -> Result {
    let descriptor = lockURL.path.withCString {
      Darwin.open($0, O_CREAT | O_RDWR, mode_t(S_IRUSR | S_IWUSR))
    }
    guard descriptor >= 0 else {
      throw GRDBAppGroupMigrationError.lockOpenFailed(lockURL, errno)
    }
    defer { _ = Darwin.close(descriptor) }

    while Darwin.lockf(descriptor, F_LOCK, 0) != 0 {
      guard errno == EINTR else {
        throw GRDBAppGroupMigrationError.lockFailed(lockURL, errno)
      }
    }
    defer { _ = Darwin.lockf(descriptor, F_ULOCK, 0) }
    return try operation()
  }

  private static func promoteExclusively(from stagingURL: URL, to databaseURL: URL) throws {
    let result = stagingURL.path.withCString { sourcePath in
      databaseURL.path.withCString { destinationPath in
        renamex_np(sourcePath, destinationPath, UInt32(RENAME_EXCL))
      }
    }
    guard result == 0 else {
      throw GRDBAppGroupMigrationError.atomicPromotionFailed(databaseURL, errno)
    }
  }

  private static func sqliteSidecarsExist(
    at databaseURL: URL,
    fileManager: FileManager,
  ) -> Bool {
    ["-wal", "-shm", "-journal"].contains {
      fileManager.fileExists(atPath: databaseURL.path + $0)
    }
  }

  private static func removeOrphanedStagingFiles(
    in directoryURL: URL,
    fileManager: FileManager,
  ) throws {
    let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .isSymbolicLinkKey]
    let candidates = try fileManager.contentsOfDirectory(
      at: directoryURL,
      includingPropertiesForKeys: Array(resourceKeys),
    )
    for candidateURL in candidates where isOwnedStagingFileName(candidateURL.lastPathComponent) {
      let values = try candidateURL.resourceValues(forKeys: resourceKeys)
      guard values.isRegularFile == true || values.isSymbolicLink == true else { continue }
      try fileManager.removeItem(at: candidateURL)
    }
  }

  private static func isOwnedStagingFileName(_ fileName: String) -> Bool {
    guard fileName.hasPrefix(stagingNamePrefix) else { return false }
    let suffixes = [".tmp-wal", ".tmp-shm", ".tmp-journal", ".tmp"]
    guard let suffix = suffixes.first(where: fileName.hasSuffix) else { return false }
    let uuidStart = fileName.index(fileName.startIndex, offsetBy: stagingNamePrefix.count)
    let uuidEnd = fileName.index(fileName.endIndex, offsetBy: -suffix.count)
    guard uuidStart < uuidEnd else { return false }
    return UUID(uuidString: String(fileName[uuidStart..<uuidEnd])) != nil
  }

  private static func removeSealedWALSidecars(
    at databaseURL: URL,
    fileManager: FileManager,
  ) throws {
    let walURL = URL(fileURLWithPath: databaseURL.path + "-wal")
    if fileManager.fileExists(atPath: walURL.path) {
      let attributes = try fileManager.attributesOfItem(atPath: walURL.path)
      guard (attributes[.size] as? NSNumber)?.intValue == 0 else {
        throw GRDBAppGroupMigrationError.stagingDatabaseHasSidecars(databaseURL)
      }
      try fileManager.removeItem(at: walURL)
    }

    let sharedMemoryURL = URL(fileURLWithPath: databaseURL.path + "-shm")
    if fileManager.fileExists(atPath: sharedMemoryURL.path) {
      try fileManager.removeItem(at: sharedMemoryURL)
    }
  }

  private static func removeSQLiteFiles(at databaseURL: URL, fileManager: FileManager) {
    for path in [
      databaseURL.path, databaseURL.path + "-wal", databaseURL.path + "-shm",
      databaseURL.path + "-journal",
    ]
    where fileManager.fileExists(atPath: path) {
      try? fileManager.removeItem(atPath: path)
    }
  }
}

private struct MigrationMarker: Codable, Equatable {
  let version: Int
  let sourceProjection: ProjectionSignature
}

private struct ProjectionSignature: Codable, Equatable {
  let todoCount: Int
  let memoCount: Int
  let digest: String
}

private struct ProjectionSnapshot: Codable, Equatable {
  let todos: [TodoProjection]
  let memos: [MemoProjection]

  func signature() throws -> ProjectionSignature {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(self)
    var hash: UInt64 = 14_695_981_039_346_656_037
    for byte in data {
      hash ^= UInt64(byte)
      hash &*= 1_099_511_628_211
    }
    return ProjectionSignature(
      todoCount: todos.count,
      memoCount: memos.count,
      digest: String(hash, radix: 16),
    )
  }
}

private struct TodoProjection: Codable, Equatable {
  let id: String
  let content: String
  let status: String
  let detail: String
  let date: Date
  let createdAt: Date
  let updatedAt: Date
  let ownerID: String
  let deletedAt: Date?
  let localRevision: Int64

  init(row: Row) {
    id = row["id"]
    content = row["content"]
    status = row["status"]
    detail = row["detail"]
    date = row["date"]
    createdAt = row["createdAt"]
    updatedAt = row["updatedAt"]
    ownerID = LocalAuthorID.canonicalizing(row["ownerId"])
    deletedAt = row["deletedAt"]
    localRevision = row["localRevision"]
  }
}

private struct MemoProjection: Codable, Equatable {
  let id: String
  let content: String
  let createdAt: Date
  let updatedAt: Date
  let ownerID: String
  let deletedAt: Date?
  let localRevision: Int64

  init(row: Row) {
    id = row["id"]
    content = row["content"]
    createdAt = row["createdAt"]
    updatedAt = row["updatedAt"]
    ownerID = LocalAuthorID.canonicalizing(row["ownerId"])
    deletedAt = row["deletedAt"]
    localRevision = row["localRevision"]
  }
}
