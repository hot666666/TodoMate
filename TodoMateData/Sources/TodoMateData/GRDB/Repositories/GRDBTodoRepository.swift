import Common
import Foundation
import GRDB
import TodoMateDomain

public final class GRDBTodoRepository: TodoRepository, Sendable {
  private let writer: any DatabaseWriter

  public init(database: GRDBDatabase) {
    writer = database.writer
  }

  public func create(_ todo: Todo) async throws {
    let record = TodoRecord(todo)
    try await writer.write { databaseConnection in
      try record.insert(databaseConnection)
    }
  }

  public func update(_ todo: Todo) async throws {
    let record = TodoRecord(todo)
    try await writer.write { databaseConnection in
      try record.update(databaseConnection)
    }
  }

  public func delete(_ todoId: String) async throws {
    try await writer.write { databaseConnection in
      guard var record = try TodoRecord.fetchOne(databaseConnection, key: todoId) else { return }
      record.isDeleted = true
      record.updatedAt = .now
      try record.update(databaseConnection)
    }
  }

  public func read(id: String) async throws -> Todo? {
    try await writer.read { databaseConnection in
      try TodoRecord
        .filter(Column("id") == id && !Column("isDeleted"))
        .fetchOne(databaseConnection)?
        .domainValue()
    }
  }

  public func readAll(query: TodoQuery, useCache _: Bool) async throws -> [Todo] {
    try await writer.read { databaseConnection in
      try self.request(for: query)
        .fetchAll(databaseConnection)
        .map { try $0.domainValue() }
    }
  }

  public func fetchCount(query: TodoQuery) async throws -> Int {
    try await writer.read { databaseConnection in
      try self.request(for: query).fetchCount(databaseConnection)
    }
  }

  public func observeTodos(query: TodoQuery) -> AsyncStream<[Todo]> {
    let observation = ValueObservation.tracking { databaseConnection in
      try self.request(for: query)
        .fetchAll(databaseConnection)
        .map { try $0.domainValue() }
    }

    return AsyncStream { continuation in
      let task = Task {
        do {
          for try await todos in observation.values(in: writer) {
            continuation.yield(todos)
          }
        } catch is CancellationError {
          // Stream termination cancels the observation task.
        } catch {
          Log.error("Todo database observation failed: \(error)", category: .data)
        }
        continuation.finish()
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  private func request(for query: TodoQuery) -> QueryInterfaceRequest<TodoRecord> {
    var request = TodoRecord
      .filter(!Column("isDeleted"))
      .order(Column("date"), Column("createdAt"))

    for filter in query.filters {
      switch filter {
      case let .owner(userId):
        request = request.filter(Column("owner") == userId)
      case let .owners(userIds):
        request = userIds.isEmpty
          ? request.none()
          : request.filter(userIds.contains(Column("owner")))
      case let .dateRange(range):
        request = request.filter(Column("date") >= range.lowerBound && Column("date") <= range.upperBound)
      case let .status(status):
        request = request.filter(Column("status") == status.rawValue)
      }
    }
    return request
  }
}
