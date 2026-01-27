import Foundation
import GRDB
import TodoMateDomain

public struct GRDBTodo: Codable, FetchableRecord, PersistableRecord, Sendable {
  public var id: String
  public var content: String
  public var statusRawValue: String
  public var detail: String
  public var date: Date
  public var createdAt: Date
  public var updatedAt: Date
  public var owner: String
  public var isDeleted: Bool

  public static let databaseTableName = "todo"

  public init(from todo: Todo) {
    self.id = todo.id
    self.content = todo.content
    self.statusRawValue = todo.status.rawValue
    self.detail = todo.detail
    self.date = todo.date
    self.createdAt = todo.createdAt
    self.updatedAt = todo.updatedAt
    self.owner = todo.owner
    self.isDeleted = todo.isDeleted
  }

  public func toDomain() -> Todo {
    Todo(
      id: id,
      content: content,
      status: TodoStatus(rawValue: statusRawValue) ?? .todo,
      detail: detail,
      date: date,
      createdAt: createdAt,
      updatedAt: updatedAt,
      owner: owner,
      isDeleted: isDeleted
    )
  }
}
