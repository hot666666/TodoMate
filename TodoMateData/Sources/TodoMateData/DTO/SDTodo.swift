//
//  SDTodo.swift
//  TodoMate
//
//  Created by hs on 07/02/25.
//

import Foundation
import SwiftData
import TodoMateDomain

@Model
public final class SDTodo {
  @Attribute(.unique) public var id: String
  public var content: String
  public var statusRawValue: String
  public var detail: String
  public var date: Date
  public var createdAt: Date
  public var updatedAt: Date
  public var owner: String
  public var isDeleted: Bool

  public init(
    id: String = UUID().uuidString,
    content: String,
    status: String,
    detail: String,
    date: Date,
    createdAt: Date,
    updatedAt: Date,
    owner: String,
    isDeleted: Bool = false,
  ) {
    self.id = id
    self.content = content
    statusRawValue = status
    self.detail = detail
    self.date = date
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.owner = owner
    self.isDeleted = isDeleted
  }
}

public extension SDTodo {
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
      isDeleted: todo.isDeleted,
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
      isDeleted: isDeleted,
    )
  }
}
