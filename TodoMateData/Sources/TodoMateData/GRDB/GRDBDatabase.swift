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
}

extension GRDBDatabase {
  func observe<Snapshot: Equatable & Sendable, Value: Sendable>(
    region: GRDBDatabaseRegion,
    fetch: @escaping @Sendable (Database) throws -> Snapshot,
    transform: @escaping @Sendable (Snapshot) -> Value,
    onError: @escaping @Sendable (Error) -> Void,
  ) -> AsyncStream<Value> {
    AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
      // Register first so a commit between subscription and the initial read is not lost.
      let changes = changeCenter.changes(in: region)
      let writer = writer
      let task = Task {
        var lastSnapshot: Snapshot?

        do {
          let snapshot = try await writer.read { databaseConnection in
            try fetch(databaseConnection)
          }
          lastSnapshot = snapshot
          continuation.yield(transform(snapshot))
        } catch is CancellationError {
          continuation.finish()
          return
        } catch {
          onError(error)
        }

        for await _ in changes {
          guard !Task.isCancelled else { break }
          do {
            let snapshot = try await writer.read { databaseConnection in
              try fetch(databaseConnection)
            }
            guard snapshot != lastSnapshot else { continue }
            lastSnapshot = snapshot
            continuation.yield(transform(snapshot))
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
