import Foundation
import GRDB
import Common

public final class GRDBDatabase: Sendable {
  public let dbWriter: any DatabaseWriter

  public init(inMemory: Bool = false) throws {
    if inMemory {
      dbWriter = try DatabaseQueue()
    } else {
      let fileManager = FileManager.default
      let appSupportURL = try fileManager.url(
        for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      let directoryURL = appSupportURL.appendingPathComponent("TodoMate", isDirectory: true)
      try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
      let databaseURL = directoryURL.appendingPathComponent("db.sqlite")

      var config = Configuration()
      config.prepareDatabase { db in
          // db.trace { print($0) } // Uncomment for debugging
      }

      dbWriter = try DatabasePool(path: databaseURL.path, configuration: config)
    }

    try migrator.migrate(dbWriter)
  }

  private var migrator: DatabaseMigrator {
    var migrator = DatabaseMigrator()

    migrator.registerMigration("v1") { db in
      try db.create(table: "todo") { t in
        t.column("id", .text).primaryKey()
        t.column("content", .text).notNull()
        t.column("statusRawValue", .text).notNull()
        t.column("detail", .text).notNull()
        t.column("date", .datetime).notNull()
        t.column("createdAt", .datetime).notNull()
        t.column("updatedAt", .datetime).notNull()
        t.column("owner", .text).notNull()
        t.column("isDeleted", .boolean).notNull().defaults(to: false)
      }

      try db.create(table: "memo") { t in
        t.column("id", .text).primaryKey()
        t.column("content", .text).notNull()
        t.column("createdAt", .datetime).notNull()
        t.column("updatedAt", .datetime).notNull()
        t.column("ownerId", .text).notNull()
        t.column("isDeleted", .boolean).notNull().defaults(to: false)
      }
    }

    return migrator
  }
}
