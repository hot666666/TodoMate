import Foundation
import GRDB
import TodoMateDomain

public final class GRDBDeletedItemsRepositoryImpl: DeletedItemsRepository, Sendable {
  private let dbWriter: any DatabaseWriter

  public init(dbWriter: any DatabaseWriter) {
    self.dbWriter = dbWriter
  }

  public func fetchAll() async throws -> [DeletedItem] {
    try await dbWriter.read { db in
      let deletedTodos = try GRDBTodo
        .filter(Column("isDeleted"))
        .fetchAll(db)
        .map { DeletedItem.todo($0.toDomain()) }

      let deletedMemos = try GRDBMemo
        .filter(Column("isDeleted"))
        .fetchAll(db)
        .map { DeletedItem.memo($0.toDomain()) }

      return (deletedTodos + deletedMemos).sorted { $0.deletedAt > $1.deletedAt }
    }
  }

  public func restore(_ item: DeletedItem) async throws {
    try await dbWriter.write { db in
      switch item {
      case let .todo(todo):
        if var existing = try GRDBTodo.fetchOne(db, key: todo.id) {
          existing.isDeleted = false
          existing.updatedAt = Date()
          try existing.update(db)
        }
      case let .memo(memo):
        if var existing = try GRDBMemo.fetchOne(db, key: memo.id) {
          existing.isDeleted = false
          existing.updatedAt = Date()
          try existing.update(db)
        }
      }
    }
  }

  public func permanentlyDelete(_ item: DeletedItem) async throws {
    try await dbWriter.write { db in
      switch item {
      case let .todo(todo):
        try GRDBTodo.deleteOne(db, key: todo.id)
      case let .memo(memo):
        try GRDBMemo.deleteOne(db, key: memo.id)
      }
    }
  }

  public func permanentlyDeleteAll() async throws {
    try await dbWriter.write { db in
      try GRDBTodo
        .filter(Column("isDeleted"))
        .deleteAll(db)

      try GRDBMemo
        .filter(Column("isDeleted"))
        .deleteAll(db)
    }
  }
}
