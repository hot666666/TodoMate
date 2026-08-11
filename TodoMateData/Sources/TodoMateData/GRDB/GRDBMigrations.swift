import GRDB

extension GRDBDatabase {
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

    migrator.registerMigration("normalizeLegacyLocalOwnerAliasesV1") { databaseConnection in
      for alias in LocalAuthorID.knownPlaceholderAliases {
        try databaseConnection.execute(
          sql: "UPDATE todo SET ownerId = ? WHERE ownerId = ?",
          arguments: [LocalAuthorID.canonical, alias],
        )
        try databaseConnection.execute(
          sql: "UPDATE memo SET ownerId = ? WHERE ownerId = ?",
          arguments: [LocalAuthorID.canonical, alias],
        )
      }
    }
    migrator.registerMigration("createProjectWorkspaceV1") { databaseConnection in
      try databaseConnection.create(table: ProjectRecord.databaseTableName) { table in
        table.column("id", .text).primaryKey()
        table.column("name", .text).notNull()
        table.column("lifecycle", .text).notNull()
        table.column("createdAt", .datetime).notNull()
        table.column("updatedAt", .datetime).notNull()
      }
      try databaseConnection.create(
        index: "project_by_createdAt",
        on: ProjectRecord.databaseTableName,
        columns: ["createdAt"],
      )
      try databaseConnection.create(table: MembershipRecord.databaseTableName) { table in
        table.column("id", .text).primaryKey()
        table.column("projectId", .text)
          .notNull()
          .references(ProjectRecord.databaseTableName, onDelete: .cascade)
        table.column("authorId", .text).notNull()
        table.column("role", .text).notNull()
        table.column("createdAt", .datetime).notNull()
        table.uniqueKey(["projectId", "authorId"])
      }
      try databaseConnection.create(table: ProjectSelectionRecord.databaseTableName) { table in
        table.column("key", .text).primaryKey()
        table.column("projectId", .text)
          .notNull()
          .references(ProjectRecord.databaseTableName, onDelete: .cascade)
      }
    }
    migrator.registerMigration("addProjectScopeToTodoV1") { databaseConnection in
      try databaseConnection.alter(table: TodoRecord.databaseTableName) { table in
        table.add(column: "projectId", .text)
          .references(ProjectRecord.databaseTableName, onDelete: .cascade)
      }
      try databaseConnection.create(
        index: "todo_by_projectId_createdAt",
        on: TodoRecord.databaseTableName,
        columns: ["projectId", "createdAt"],
      )
    }
    return migrator
  }
}
