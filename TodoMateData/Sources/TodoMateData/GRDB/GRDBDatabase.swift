import Common
import Foundation
import GRDB
import SQLite3

public final class GRDBDatabase: Sendable {
  public enum Storage: Sendable {
    case shared
    case inMemory
    case file(URL)
  }

  let writer: any DatabaseWriter
  let changeCenter: GRDBDatabaseChangeCenter
  private let changeObservers: [AnyDatabaseCancellable]

  public init(storage: Storage = .shared) throws {
    let openedWriter: any DatabaseWriter
    let notificationBaseName: String?

    switch storage {
    case .inMemory:
      let queue = try DatabaseQueue()
      try Self.migrator.migrate(queue)
      openedWriter = queue
      notificationBaseName = nil
    case let .file(url):
      openedWriter = try Self.openCoordinatedDatabase(at: url, legacyStoreURLs: [])
      notificationBaseName = Self.changeNotificationBaseName(for: url)
    case .shared:
      let locations = try Self.prepareSharedLocations()
      openedWriter = try Self.openCoordinatedDatabase(
        at: locations.databaseURL,
        legacyStoreURLs: locations.legacyStoreURLs,
      )
      notificationBaseName = Self.changeNotificationBaseName(for: locations.databaseURL)
    }

    writer = openedWriter
    let changeCenter = GRDBDatabaseChangeCenter(baseNotificationName: notificationBaseName)
    self.changeCenter = changeCenter
    changeObservers = Self.startChangeObservers(in: openedWriter, changeCenter: changeCenter)
  }

  static func sharedDatabaseURL() throws -> URL {
    let groupURL = try sharedGroupURL()
    return groupURL
      .appendingPathComponent("Library/Application Support", isDirectory: true)
      .appendingPathComponent(AppEnvironment.Container.name, isDirectory: true)
      .appendingPathComponent("TodoMate.sqlite")
  }

  private static func prepareSharedLocations() throws -> (
    databaseURL: URL,
    legacyStoreURLs: [URL],
  ) {
    let fileManager = FileManager.default
    let groupURL = try sharedGroupURL()
    let supportURL = groupURL.appendingPathComponent("Library/Application Support", isDirectory: true)
    let directoryURL = supportURL.appendingPathComponent(AppEnvironment.Container.name, isDirectory: true)
    try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    let legacyStoreURLs = [
      supportURL.appendingPathComponent("\(AppEnvironment.Container.name).store"),
      supportURL.appendingPathComponent("default.store"),
      groupURL.appendingPathComponent("default.store"),
    ]
    return (directoryURL.appendingPathComponent("TodoMate.sqlite"), legacyStoreURLs)
  }

  private static func sharedGroupURL() throws -> URL {
    guard let groupURL = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: AppEnvironment.Container.appGroupIdentifier,
    ) else {
      throw LocalDatabaseError.appGroupContainerUnavailable(
        AppEnvironment.Container.appGroupIdentifier,
      )
    }
    return groupURL
  }

  private static func openCoordinatedDatabase(
    at databaseURL: URL,
    legacyStoreURLs: [URL],
  ) throws -> DatabasePool {
    let coordinator = NSFileCoordinator(filePresenter: nil)
    var coordinatorError: NSError?
    var databaseError: Error?
    var pool: DatabasePool?

    coordinator.coordinate(
      writingItemAt: databaseURL,
      options: .forMerging,
      error: &coordinatorError,
    ) { coordinatedURL in
      do {
        let openedPool = try makePool(at: coordinatedURL)
        try migrator.migrate(openedPool)
        try LegacySwiftDataImporter.importIfNeeded(
          from: legacyStoreURLs,
          into: openedPool,
        )
        pool = openedPool
      } catch {
        databaseError = error
      }
    }

    if let error = databaseError ?? coordinatorError {
      throw error
    }
    guard let pool else {
      throw LocalDatabaseError.databaseCoordinationFailed(databaseURL)
    }
    return pool
  }

  private static func makePool(at url: URL) throws -> DatabasePool {
    var configuration = Configuration()
    configuration.busyMode = .timeout(5)
    configuration.prepareDatabase { databaseConnection in
      try databaseConnection.execute(sql: "PRAGMA foreign_keys = ON")

      var persistentWAL: CInt = 1
      let resultCode = withUnsafeMutablePointer(to: &persistentWAL) { flag in
        sqlite3_file_control(
          databaseConnection.sqliteConnection,
          nil,
          SQLITE_FCNTL_PERSIST_WAL,
          flag,
        )
      }
      guard resultCode == SQLITE_OK else {
        throw DatabaseError(resultCode: ResultCode(rawValue: resultCode))
      }
    }
    return try DatabasePool(path: url.path, configuration: configuration)
  }

  private static func changeNotificationBaseName(for databaseURL: URL) -> String {
    var hash: UInt64 = 14_695_981_039_346_656_037
    for byte in databaseURL.standardizedFileURL.path.utf8 {
      hash ^= UInt64(byte)
      hash &*= 1_099_511_628_211
    }
    return "\(AppEnvironment.Container.appGroupIdentifier).database.\(String(hash, radix: 16))"
  }

  private static func startChangeObservers(
    in writer: any DatabaseWriter,
    changeCenter: GRDBDatabaseChangeCenter,
  ) -> [AnyDatabaseCancellable] {
    let todoObserver = DatabaseRegionObservation(tracking: TodoRecord.all()).start(
      in: writer,
      onError: { error in
        Log.error("Todo database region observation failed: \(error)", category: .data)
      },
      onChange: { _ in
        changeCenter.notifyChange(in: .todo)
      },
    )
    let memoObserver = DatabaseRegionObservation(tracking: MemoRecord.all()).start(
      in: writer,
      onError: { error in
        Log.error("Memo database region observation failed: \(error)", category: .data)
      },
      onChange: { _ in
        changeCenter.notifyChange(in: .memo)
      },
    )
    return [todoObserver, memoObserver]
  }

  static var migrator: DatabaseMigrator {
    var migrator = DatabaseMigrator()
    migrator.registerMigration("createLocalItems") { databaseConnection in
      try databaseConnection.create(table: TodoRecord.databaseTableName) { table in
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

      try databaseConnection.create(table: MemoRecord.databaseTableName) { table in
        table.column("id", .text).primaryKey()
        table.column("content", .text).notNull()
        table.column("createdAt", .datetime).notNull()
        table.column("updatedAt", .datetime).notNull()
        table.column("owner", .text).notNull()
        table.column("isDeleted", .boolean).notNull().defaults(to: false)
      }

      try databaseConnection.create(
        index: "todo_by_date",
        on: TodoRecord.databaseTableName,
        columns: ["date"],
      )
      try databaseConnection.create(
        index: "todo_by_owner_date",
        on: TodoRecord.databaseTableName,
        columns: ["owner", "date"],
      )
      try databaseConnection.create(
        index: "memo_by_owner_updatedAt",
        on: MemoRecord.databaseTableName,
        columns: ["owner", "updatedAt"],
      )

      try databaseConnection.create(table: "localMetadata") { table in
        table.column("key", .text).primaryKey()
        table.column("value", .text).notNull()
      }
    }

    migrator.registerMigration("normalizeLocalItemMetadata") { databaseConnection in
      try databaseConnection.alter(table: TodoRecord.databaseTableName) { table in
        table.rename(column: "owner", to: "ownerId")
        table.add(column: "deletedAt", .datetime)
        table.add(column: "localRevision", .integer).notNull().defaults(to: 1)
      }
      try databaseConnection.execute(
        sql: "UPDATE todo SET deletedAt = updatedAt WHERE isDeleted = 1",
      )
      try databaseConnection.alter(table: TodoRecord.databaseTableName) { table in
        table.drop(column: "isDeleted")
      }

      try databaseConnection.alter(table: MemoRecord.databaseTableName) { table in
        table.rename(column: "owner", to: "ownerId")
        table.add(column: "deletedAt", .datetime)
        table.add(column: "localRevision", .integer).notNull().defaults(to: 1)
      }
      try databaseConnection.execute(
        sql: "UPDATE memo SET deletedAt = updatedAt WHERE isDeleted = 1",
      )
      try databaseConnection.alter(table: MemoRecord.databaseTableName) { table in
        table.drop(column: "isDeleted")
      }

      try databaseConnection.drop(index: "todo_by_owner_date")
      try databaseConnection.drop(index: "memo_by_owner_updatedAt")
      try databaseConnection.create(
        index: "todo_by_ownerId_date",
        on: TodoRecord.databaseTableName,
        columns: ["ownerId", "date"],
      )
      try databaseConnection.create(
        index: "todo_by_updatedAt",
        on: TodoRecord.databaseTableName,
        columns: ["updatedAt"],
      )
      try databaseConnection.create(
        index: "todo_by_deletedAt",
        on: TodoRecord.databaseTableName,
        columns: ["deletedAt"],
      )
      try databaseConnection.create(
        index: "memo_by_ownerId_updatedAt",
        on: MemoRecord.databaseTableName,
        columns: ["ownerId", "updatedAt"],
      )
      try databaseConnection.create(
        index: "memo_by_deletedAt",
        on: MemoRecord.databaseTableName,
        columns: ["deletedAt"],
      )
    }
    return migrator
  }
}

extension GRDBDatabase {
  func observe<Value: Equatable & Sendable>(
    region: GRDBDatabaseRegion,
    fetch: @escaping @Sendable (Database) throws -> Value,
    onError: @escaping @Sendable (Error) -> Void,
  ) -> AsyncStream<Value> {
    AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
      // Register first so a commit between subscription and the initial read is not lost.
      let changes = changeCenter.changes(in: region)
      let writer = writer
      let task = Task {
        var lastValue: Value?

        do {
          let value = try await writer.read { databaseConnection in
            try fetch(databaseConnection)
          }
          lastValue = value
          continuation.yield(value)
        } catch is CancellationError {
          continuation.finish()
          return
        } catch {
          onError(error)
        }

        for await _ in changes {
          guard !Task.isCancelled else { break }
          do {
            let value = try await writer.read { databaseConnection in
              try fetch(databaseConnection)
            }
            guard value != lastValue else { continue }
            lastValue = value
            continuation.yield(value)
          } catch is CancellationError {
            break
          } catch {
            onError(error)
          }
        }
        continuation.finish()
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }
}
