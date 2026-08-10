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
        .map { DeletedItem.todo($0.domainValue(), snapshotRevision: $0.localRevision) }
      let memos = try MemoRecord
        .filter(MemoRecord.Columns.deletedAt != nil)
        .fetchAll(databaseConnection)
        .map { DeletedItem.memo($0.domainValue(), snapshotRevision: $0.localRevision) }
      return (todos + memos).sorted { $0.deletedAt > $1.deletedAt }
    }
  }

  public func restore(_ item: DeletedItem) async throws {
    try await writer.write { databaseConnection in
      switch item {
      case let .todo(todo, snapshotRevision):
        var request = TodoRecord.filter(
          TodoRecord.Columns.id == todo.id
            && TodoRecord.Columns.deletedAt == todo.updatedAt,
        )
        if let snapshotRevision {
          request = request.filter(TodoRecord.Columns.localRevision == snapshotRevision)
        }
        guard var record = try request.fetchOne(databaseConnection)
        else { return }
        guard try record.restore(at: databaseConnection.transactionDate) else { return }
        try record.update(databaseConnection)
      case let .memo(memo, snapshotRevision):
        var request = MemoRecord.filter(
          MemoRecord.Columns.id == memo.id
            && MemoRecord.Columns.deletedAt == memo.updatedAt,
        )
        if let snapshotRevision {
          request = request.filter(MemoRecord.Columns.localRevision == snapshotRevision)
        }
        guard var record = try request.fetchOne(databaseConnection)
        else { return }
        guard try record.restore(at: databaseConnection.transactionDate) else { return }
        try record.update(databaseConnection)
      }
    }
  }

  public func permanentlyDelete(_ item: DeletedItem) async throws {
    try await writer.write { databaseConnection in
      switch item {
      case let .todo(todo, snapshotRevision):
        var request = TodoRecord.filter(TodoRecord.Columns.id == todo.id)
        if let snapshotRevision {
          request = request.filter(
            TodoRecord.Columns.deletedAt == todo.updatedAt
              && TodoRecord.Columns.localRevision == snapshotRevision,
          )
        } else {
          request = request.filter(
            TodoRecord.Columns.deletedAt == nil
              && TodoRecord.Columns.updatedAt == todo.updatedAt,
          )
        }
        _ = try request.deleteAll(databaseConnection)
      case let .memo(memo, snapshotRevision):
        var request = MemoRecord.filter(MemoRecord.Columns.id == memo.id)
        if let snapshotRevision {
          request = request.filter(
            MemoRecord.Columns.deletedAt == memo.updatedAt
              && MemoRecord.Columns.localRevision == snapshotRevision,
          )
        } else {
          request = request.filter(
            MemoRecord.Columns.deletedAt == nil
              && MemoRecord.Columns.updatedAt == memo.updatedAt,
          )
        }
        _ = try request.deleteAll(databaseConnection)
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
