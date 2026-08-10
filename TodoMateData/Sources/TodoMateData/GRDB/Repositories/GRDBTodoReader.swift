import GRDB
import TodoMateDomain

/// Narrow query surface for read-only consumers such as the widget extension.
public final class GRDBTodoReader: Sendable {
  private let reader: any DatabaseReader

  public init(database: GRDBReadOnlyDatabase) {
    reader = database.reader
  }

  public func fetch(query: TodoQuery) async throws -> [Todo] {
    try await reader.read { databaseConnection in
      try TodoRecord.activeRequest(for: query)
        .fetchAll(databaseConnection)
        .map { $0.domainValue() }
    }
  }
}
