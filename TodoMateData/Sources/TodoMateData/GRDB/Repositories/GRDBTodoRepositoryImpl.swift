import Foundation
import GRDB
import TodoMateDomain

public final class GRDBTodoRepositoryImpl: TodoRepository, Sendable {
  private let dbWriter: any DatabaseWriter

  public init(dbWriter: any DatabaseWriter) {
    self.dbWriter = dbWriter
  }

  public func create(_ todo: Todo) async throws {
    let grdbTodo = GRDBTodo(from: todo)
    try await dbWriter.write { db in
      try grdbTodo.insert(db)
    }
  }

  public func update(_ todo: Todo) async throws {
    let grdbTodo = GRDBTodo(from: todo)
    try await dbWriter.write { db in
      try grdbTodo.update(db)
    }
  }

  public func delete(_ todoId: String) async throws {
    try await dbWriter.write { db in
      // Soft delete as per SDTodo implementation
      if var todo = try GRDBTodo.fetchOne(db, key: todoId) {
        todo.isDeleted = true
        todo.updatedAt = Date()
        try todo.update(db)
      }
    }
  }

  public func read(id: String) async throws -> Todo? {
    try await dbWriter.read { db in
      try GRDBTodo
        .filter(Column("id") == id && !Column("isDeleted"))
        .fetchOne(db)?
        .toDomain()
    }
  }

  public func readAll(query: TodoQuery, useCache _: Bool) async throws -> [Todo] {
    try await dbWriter.read { db in
      try self.makeRequest(query: query)
        .fetchAll(db)
        .map { $0.toDomain() }
    }
  }

  public func fetchCount(query: TodoQuery) async throws -> Int {
    try await dbWriter.read { db in
      try self.makeRequest(query: query).fetchCount(db)
    }
  }

  public func observeTodos(query: TodoQuery) -> AsyncStream<[Todo]> {
    let request = makeRequest(query: query)
    let observation = ValueObservation.tracking { db in
      try request.fetchAll(db).map { $0.toDomain() }
    }

    // Using immediate scheduling to mimic CurrentValueSubject behavior if needed,
    // but default async is fine.

    return AsyncStream { continuation in
      let cancellable = observation.start(in: dbWriter, onError: { error in
        print("GRDB Observation error: \(error)")
      }, onChange: { todos in
        continuation.yield(todos)
      })

      continuation.onTermination = { _ in
        cancellable.cancel()
      }
    }
  }

  private func makeRequest(query: TodoQuery) -> QueryInterfaceRequest<GRDBTodo> {
    var request = GRDBTodo
      .filter(!Column("isDeleted"))
      .order(Column("date"))

    var dateRange: ClosedRange<Date>?
    for filter in query.filters {
      if case let .dateRange(range) = filter {
        dateRange = range
      }
    }

    if let dateRange {
      request = request.filter(Column("date") >= dateRange.lowerBound && Column("date") <= dateRange.upperBound)
    }

    return request
  }
}
