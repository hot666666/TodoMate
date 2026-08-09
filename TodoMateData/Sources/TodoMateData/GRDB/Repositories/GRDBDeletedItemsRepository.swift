import Foundation
import GRDB
import TodoMateDomain

public final class GRDBDeletedItemsRepository: DeletedItemsRepository, Sendable {
  private let writer: any DatabaseWriter

  public init(database: GRDBDatabase) {
    writer = database.writer
  }

  public func fetchAll() async throws -> [DeletedItem] {
    try await writer.read { databaseConnection in
      let todos = try TodoRecord
        .filter(TodoRecord.Columns.deletedAt != nil)
        .fetchAll(databaseConnection)
        .map { DeletedItem.todo($0.domainValue()) }
      let memos = try MemoRecord
        .filter(MemoRecord.Columns.deletedAt != nil)
        .fetchAll(databaseConnection)
        .map { DeletedItem.memo($0.domainValue()) }
      return (todos + memos).sorted { $0.deletedAt > $1.deletedAt }
    }
  }

  public func restore(_ item: DeletedItem) async throws {
    try await writer.write { databaseConnection in
      switch item {
      case let .todo(todo):
        guard var record = try TodoRecord.fetchOne(databaseConnection, key: todo.id) else { return }
        guard try record.restore(at: databaseConnection.transactionDate) else { return }
        try record.update(databaseConnection)
      case let .memo(memo):
        guard var record = try MemoRecord.fetchOne(databaseConnection, key: memo.id) else { return }
        guard try record.restore(at: databaseConnection.transactionDate) else { return }
        try record.update(databaseConnection)
      }
    }
  }

  public func permanentlyDelete(_ item: DeletedItem) async throws {
    try await writer.write { databaseConnection in
      switch item {
      case let .todo(todo):
        _ = try TodoRecord.deleteOne(databaseConnection, key: todo.id)
      case let .memo(memo):
        _ = try MemoRecord.deleteOne(databaseConnection, key: memo.id)
      }
    }
  }

  public func permanentlyDeleteAll() async throws {
    try await writer.write { databaseConnection in
      _ = try TodoRecord.filter(TodoRecord.Columns.deletedAt != nil).deleteAll(databaseConnection)
      _ = try MemoRecord.filter(MemoRecord.Columns.deletedAt != nil).deleteAll(databaseConnection)
    }
  }
}
