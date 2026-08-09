import Foundation
import GRDB
import TodoMateDomain

struct TodoRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
  static let databaseTableName = "todo"

  var id: String
  var content: String
  var status: String
  var detail: String
  var date: Date
  var createdAt: Date
  var updatedAt: Date
  var owner: String
  var isDeleted: Bool

  init(
    id: String,
    content: String,
    status: String,
    detail: String,
    date: Date,
    createdAt: Date,
    updatedAt: Date,
    owner: String,
    isDeleted: Bool,
  ) {
    self.id = id
    self.content = content
    self.status = status
    self.detail = detail
    self.date = date
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.owner = owner
    self.isDeleted = isDeleted
  }

  init(_ todo: Todo) {
    id = todo.id
    content = todo.content
    status = todo.status.rawValue
    detail = todo.detail
    date = todo.date
    createdAt = todo.createdAt
    updatedAt = todo.updatedAt
    owner = todo.owner
    isDeleted = todo.isDeleted
  }

  func domainValue() throws -> Todo {
    guard let status = TodoStatus(rawValue: status) else {
      throw LocalDatabaseError.invalidTodoStatus(status)
    }
    return Todo(
      id: id,
      content: content,
      status: status,
      detail: detail,
      date: date,
      createdAt: createdAt,
      updatedAt: updatedAt,
      owner: owner,
      isDeleted: isDeleted,
    )
  }
}
