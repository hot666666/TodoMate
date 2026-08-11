import Common
import Foundation
import GRDB
import TodoMateDomain

public final class GRDBTodoRepository: TodoRepository, Sendable {
  private let database: GRDBDatabase

  public init(database: GRDBDatabase) {
    self.database = database
  }

  public func create(_ todo: Todo) async throws {
    let record = TodoRecord(todo)
    try await database.writer.write { databaseConnection in
      try record.insert(databaseConnection)
    }
  }

  public func update(_ todo: Todo) async throws {
    try await database.writer.write { databaseConnection in
      guard var record = try TodoRecord
        .filter(
          TodoRecord.Columns.id == todo.id
            && TodoRecord.Columns.projectID == nil
            && TodoRecord.Columns.deletedAt == nil,
        )
        .fetchOne(databaseConnection)
      else {
        throw TodoRecord.recordNotFound(databaseConnection, key: todo.id)
      }
      try record.apply(todo, at: databaseConnection.transactionDate)
      try record.update(databaseConnection)
    }
  }

  public func delete(_ todoId: String) async throws {
    try await database.writer.write { databaseConnection in
      guard var record = try TodoRecord
        .filter(TodoRecord.Columns.id == todoId && TodoRecord.Columns.projectID == nil)
        .fetchOne(databaseConnection)
      else { return }
      guard try record.markDeleted(at: databaseConnection.transactionDate) else { return }
      try record.update(databaseConnection)
    }
  }

  public func read(id: String) async throws -> Todo? {
    try await database.writer.read { databaseConnection in
      try TodoRecord
        .filter(
          TodoRecord.Columns.id == id
            && TodoRecord.Columns.projectID == nil
            && TodoRecord.Columns.deletedAt == nil,
        )
        .fetchOne(databaseConnection)?
        .domainValue()
    }
  }

  public func readAll(query: TodoQuery, useCache _: Bool) async throws -> [Todo] {
    try await database.writer.read { databaseConnection in
      try TodoRecord.activeRequest(for: query)
        .fetchAll(databaseConnection)
        .map { $0.domainValue() }
    }
  }

  public func fetchCount(query: TodoQuery) async throws -> Int {
    try await database.writer.read { databaseConnection in
      try TodoRecord.activeRequest(for: query).fetchCount(databaseConnection)
    }
  }

  public func observeTodos(query: TodoQuery) -> AsyncStream<[Todo]> {
    database.observe(
      region: .todo,
      fetch: { databaseConnection in
        try TodoRecord.activeRequest(for: query)
          .fetchAll(databaseConnection)
      },
      transform: { records in records.map { $0.domainValue() } },
      onError: { error in
        Log.error("Todo database observation failed: \(error)", category: .data)
      },
    )
  }
}
