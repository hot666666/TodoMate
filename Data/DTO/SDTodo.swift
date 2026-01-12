//
//  SDTodo.swift
//  TodoMate
//
//  Created by hs on 07/02/25.
//

import Foundation
import SwiftData

@Model
final class SDTodo {
  @Attribute(.unique) var id: String
  var content: String
  var statusRawValue: String
  var detail: String
  var date: Date
  var createdAt: Date
  var updatedAt: Date
  var owner: String

  init(
    id: String = UUID().uuidString,
    content: String,
    status: String,
    detail: String,
    date: Date,
    createdAt: Date,
    updatedAt: Date,
    owner: String,
  ) {
    self.id = id
    self.content = content
    statusRawValue = status
    self.detail = detail
    self.date = date
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.owner = owner
  }
}

extension SDTodo {
  /// Domain Entity -> SwiftData Model
  convenience init(from todo: Todo) {
    self.init(
      id: todo.id,
      content: todo.content,
      status: todo.status.rawValue,
      detail: todo.detail,
      date: todo.date,
      createdAt: todo.createdAt,
      updatedAt: todo.updatedAt,
      owner: todo.owner,
    )
  }

  /// SwiftData Model -> Domain Entity
  func toDomain() -> Todo {
    Todo(
      id: id,
      content: content,
      status: TodoStatus(rawValue: statusRawValue) ?? .todo,
      detail: detail,
      date: date,
      createdAt: createdAt,
      updatedAt: updatedAt,
      owner: owner,
    )
  }
}
