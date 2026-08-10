//
//  TodoEntity.swift
//  TodoMate
//
//  Created by agent on 1/16/26.
//

import AppIntents
import Foundation
import TodoMateDomain

struct TodoEntity: AppEntity {
  static let defaultQuery = TodoEntityQuery()
  static let typeDisplayRepresentation: TypeDisplayRepresentation = "Todo"

  var id: String
  var content: String
  var status: String
  var date: Date
  var isDeleted: Bool

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(content)", subtitle: "\(status)")
  }

  init(id: String, content: String, status: String, date: Date, isDeleted: Bool) {
    self.id = id
    self.content = content
    self.status = status
    self.date = date
    self.isDeleted = isDeleted
  }

  init(from todo: Todo) {
    id = todo.id
    content = todo.content
    status = todo.status.rawValue
    date = todo.date
    isDeleted = todo.isDeleted
  }
}

struct TodoEntityQuery: EntityQuery {
  @Dependency
  private var container: CoreDIContainer

  func entities(for identifiers: [String]) async throws -> [TodoEntity] {
    var result: [TodoEntity] = []
    for id in identifiers {
      if let todo = try await container.localTodoRepository.read(id: id) {
        result.append(TodoEntity(from: todo))
      }
    }
    return result
  }

  func suggestedEntities() async throws -> [TodoEntity] {
    let todos = try await container.localTodoRepository.readAll(
      query: TodoQuery(),
      useCache: false,
    )
    return todos
      .sorted { $0.updatedAt > $1.updatedAt }
      .prefix(20)
      .map(TodoEntity.init(from:))
  }
}
