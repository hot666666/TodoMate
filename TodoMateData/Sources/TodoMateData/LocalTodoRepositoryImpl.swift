//
//  LocalTodoRepositoryImpl.swift
//  TodoMate
//
//  Created by hs on 07/02/25.
//

import Foundation
import SwiftData
import TodoMateDomain

@ModelActor
public actor SwiftDataTodoRepositoryImpl: TodoRepository {
  // @ModelActor provides `modelContext` and `modelExecutor`

  public func create(_ todo: Todo) async throws {
    let sdTodo = SDTodo(from: todo)
    modelContext.insert(sdTodo)
    try modelContext.save()
  }

  public func update(_ todo: Todo) async throws {
    let id = todo.id
    let descriptor = FetchDescriptor<SDTodo>(predicate: #Predicate { $0.id == id })

    if let existing = try modelContext.fetch(descriptor).first {
      existing.content = todo.content
      existing.statusRawValue = todo.status.rawValue
      existing.detail = todo.detail
      existing.date = todo.date
      existing.updatedAt = Date()
      existing.owner = todo.owner
    }
    try modelContext.save()
  }

  public func delete(_ todoId: String) async throws {
    let descriptor = FetchDescriptor<SDTodo>(predicate: #Predicate { $0.id == todoId })
    if let existing = try modelContext.fetch(descriptor).first {
      modelContext.delete(existing)
    }
    try modelContext.save()
  }

  public func readAll(query: TodoQuery, useCache _: Bool) async throws -> [Todo] {
    var dateRange: ClosedRange<Date>?
    for filter in query.filters {
      if case let .dateRange(range) = filter {
        dateRange = range
      }
    }

    let descriptor: FetchDescriptor<SDTodo>
    if let dateRange {
      let start = dateRange.lowerBound
      let end = dateRange.upperBound
      descriptor = FetchDescriptor<SDTodo>(
        predicate: #Predicate<SDTodo> { $0.date >= start && $0.date <= end },
        sortBy: [SortDescriptor(\.date)],
      )
    } else {
      descriptor = FetchDescriptor<SDTodo>(sortBy: [SortDescriptor(\.date)])
    }

    let allSDTodos = try modelContext.fetch(descriptor)
    return allSDTodos.map { $0.toDomain() }
  }
}
