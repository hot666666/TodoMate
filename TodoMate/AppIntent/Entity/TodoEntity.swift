//
//  TodoEntity.swift
//  TodoMate
//
//  Created by agent on 1/16/26.
//

import AppIntents
import Foundation
import SwiftData
import TodoMateData
import TodoMateDomain

struct TodoEntity: AppEntity {
  static var defaultQuery = TodoEntityQuery()
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Todo"

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
    let container = container.modelContainer

    let context = ModelContext(container)
    var result: [TodoEntity] = []

    // ID 리스트가 많지 않으므로 반복 조회 허용.
    // 성능 최적화가 필요하면 FetchDescriptor(predicate: id in ids)를 쓸 수 있으나 SwiftData Predicate 복잡성 회피.
    for id in identifiers {
      let descriptor = FetchDescriptor<SDTodo>(predicate: #Predicate { $0.id == id })
      if let sdTodo = try? context.fetch(descriptor).first {
        result.append(TodoEntity(from: sdTodo.toDomain()))
      }
    }

    return result
  }

  func suggestedEntities() async throws -> [TodoEntity] {
    let container = container.modelContainer

    let context = ModelContext(container)
    // 최근 수정된 순서로 20개 조회
    var descriptor = FetchDescriptor<SDTodo>(sortBy: [
      SortDescriptor(\.updatedAt, order: .reverse),
    ])
    descriptor.fetchLimit = 20

    do {
      let sdTodos = try context.fetch(descriptor)
      return sdTodos.map { TodoEntity(from: $0.toDomain()) }
    } catch {
      return []
    }
  }
}
