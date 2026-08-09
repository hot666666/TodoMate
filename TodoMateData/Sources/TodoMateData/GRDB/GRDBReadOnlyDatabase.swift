import Foundation
import GRDB

/// A schema-validated, read-only connection for extensions that consume the shared database.
public final class GRDBReadOnlyDatabase: Sendable {
  public enum Storage: Sendable {
    case shared
    case file(URL)
  }

  let reader: any DatabaseReader

  /// Returns `nil` when the database does not exist yet or its schema does not match this build.
  public init?(storage: Storage = .shared) throws {
    let databaseURL = switch storage {
    case .shared:
      try GRDBDatabase.sharedDatabaseURL()
    case let .file(url):
      url
    }

    guard let reader = try Self.openCoordinatedDatabase(at: databaseURL) else { return nil }
    self.reader = reader
  }

  private static func openCoordinatedDatabase(at databaseURL: URL) throws -> DatabasePool? {
    let coordinator = NSFileCoordinator(filePresenter: nil)
    var coordinatorError: NSError?
    var databaseError: Error?
    var openedPool: DatabasePool?
    var didCoordinate = false

    coordinator.coordinate(
      readingItemAt: databaseURL,
      options: .withoutChanges,
      error: &coordinatorError,
    ) { coordinatedURL in
      didCoordinate = true
      do {
        openedPool = try makePoolIfReady(at: coordinatedURL)
      } catch {
        databaseError = error
      }
    }

    if let error = databaseError ?? coordinatorError {
      throw error
    }
    guard didCoordinate else {
      throw LocalDatabaseError.databaseCoordinationFailed(databaseURL)
    }
    return openedPool
  }

  private static func makePoolIfReady(at databaseURL: URL) throws -> DatabasePool? {
    do {
      var configuration = Configuration()
      configuration.readonly = true
      configuration.busyMode = .timeout(5)
      let pool = try DatabasePool(path: databaseURL.path, configuration: configuration)

      let hasCurrentSchema = try pool.read { databaseConnection in
        let migrator = GRDBDatabase.migrator
        let isTooRecent = try migrator.hasBeenSuperseded(databaseConnection)
        let isTooOld = try !migrator.hasCompletedMigrations(databaseConnection)
        return !isTooRecent && !isTooOld
      }
      return hasCurrentSchema ? pool : nil
    } catch {
      guard FileManager.default.fileExists(atPath: databaseURL.path) else { return nil }
      throw error
    }
  }
}
