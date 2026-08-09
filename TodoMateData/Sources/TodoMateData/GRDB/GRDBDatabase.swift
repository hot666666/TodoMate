import Common
import Foundation
import GRDB

public final class GRDBDatabase: Sendable {
  public enum Storage: Sendable {
    case shared
    case inMemory
    case file(URL)
  }

  public let writer: any DatabaseWriter

  public init(storage: Storage = .shared) throws {
    let legacyStoreURLs: [URL]
    switch storage {
    case .inMemory:
      writer = try DatabaseQueue()
      legacyStoreURLs = []
    case let .file(url):
      writer = try Self.makePool(at: url)
      legacyStoreURLs = []
    case .shared:
      let locations = try Self.sharedLocations()
      writer = try Self.makePool(at: locations.databaseURL)
      legacyStoreURLs = locations.legacyStoreURLs
    }

    try Self.migrator.migrate(writer)
    try LegacySwiftDataImporter.importIfNeeded(from: legacyStoreURLs, into: writer)
  }

  private static func sharedLocations() throws -> (databaseURL: URL, legacyStoreURLs: [URL]) {
    let fileManager = FileManager.default
    let groupURL = fileManager.containerURL(
      forSecurityApplicationGroupIdentifier: AppEnvironment.Container.appGroupIdentifier,
    )
    let supportURL: URL = if let groupURL {
      groupURL.appendingPathComponent("Library/Application Support", isDirectory: true)
    } else {
      fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }

    let directoryURL = supportURL.appendingPathComponent(AppEnvironment.Container.name, isDirectory: true)
    try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    var legacyStoreURLs = [
      supportURL.appendingPathComponent("\(AppEnvironment.Container.name).store"),
      supportURL.appendingPathComponent("default.store"),
    ]
    if let groupURL {
      legacyStoreURLs.append(groupURL.appendingPathComponent("default.store"))
    }
    return (directoryURL.appendingPathComponent("TodoMate.sqlite"), legacyStoreURLs)
  }

  private static func makePool(at url: URL) throws -> DatabasePool {
    var configuration = Configuration()
    configuration.busyMode = .timeout(5)
    configuration.prepareDatabase { databaseConnection in
      try databaseConnection.execute(sql: "PRAGMA foreign_keys = ON")
    }
    return try DatabasePool(path: url.path, configuration: configuration)
  }

  private static var migrator: DatabaseMigrator {
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
    return migrator
  }
}
