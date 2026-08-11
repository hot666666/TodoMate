import Common
import Foundation
import GRDB
import TodoMateApplication
import TodoMateDomain

public final class GRDBProjectTodoPersistence: ProjectTodoPersistence, Sendable {
  private let database: GRDBDatabase

  public init(database: GRDBDatabase) {
    self.database = database
  }

  public func observe(projectID: ProjectID) -> AsyncStream<[ProjectTodo]> {
    database.observe(
      region: .todo,
      fetch: { databaseConnection in
        try TodoRecord
          .filter(TodoRecord.Columns.projectID == projectID.rawValue)
          .filter(TodoRecord.Columns.deletedAt == nil)
          .order(TodoRecord.Columns.createdAt, TodoRecord.Columns.id)
          .fetchAll(databaseConnection)
          .map { try $0.projectTodoValue() }
      },
      transform: { $0 },
      onError: { error in
        Log.error("Project Todo observation failed: \(error)", category: .data)
      },
    )
  }

  public func create(_ todo: ProjectTodo) async throws {
    try await database.writer.write { databaseConnection in
      try TodoRecord(todo).insert(databaseConnection)
    }
  }
}

public extension TodoClient {
  static func grdb(
    database: GRDBDatabase,
    generateID: @escaping @Sendable () -> TodoID = { TodoID(rawValue: UUID().uuidString) },
    currentAuthorID: ContentAuthorID = ContentAuthorID(rawValue: User.local.id),
    now: @escaping @Sendable () -> Date = Date.init,
  ) -> Self {
    .live(
      persistence: GRDBProjectTodoPersistence(database: database),
      generateID: generateID,
      currentAuthorID: currentAuthorID,
      now: now,
    )
  }
}
