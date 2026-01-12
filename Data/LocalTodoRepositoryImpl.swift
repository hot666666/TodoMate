//
//  LocalTodoRepositoryImpl.swift
//  TodoMate
//
//  Created by hs on 07/02/25.
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataTodoRepositoryImpl: TodoRepository {
  // @ModelActor provides `modelContext` and `modelExecutor`

  func create(_ todo: Todo) async throws {
    let sdTodo = SDTodo(from: todo)
    modelContext.insert(sdTodo)
    try modelContext.save()
  }

  func update(_ todo: Todo) async throws {
    let id = todo.id
    // SwiftData predicate construction for ID match
    let descriptor = FetchDescriptor<SDTodo>(predicate: #Predicate { $0.id == id })

    if let existing = try modelContext.fetch(descriptor).first {
      existing.content = todo.content
      existing.statusRawValue = todo.status.rawValue
      existing.detail = todo.detail
      existing.date = todo.date
      existing.updatedAt = Date() // Update timestamp
      existing.owner = todo.owner
    }
    try modelContext.save()
  }

  func delete(_ todoId: String) async throws {
    let descriptor = FetchDescriptor<SDTodo>(predicate: #Predicate { $0.id == todoId })
    if let existing = try modelContext.fetch(descriptor).first {
      modelContext.delete(existing)
    }
    try modelContext.save()
  }

  func readAll(query: TodoQuery, source _: DataSource) async throws -> [Todo] {
    // Note: 'source' is ignored as this is strictly the local repository.

    // Construct predicate based on query filters
    // SwiftData #Predicate is strict. We cannot easily compose dynamic predicates yet without complex logic.
    // Simplifying: Fetch all and filter in memory for complex cases,
    // OR separate common patterns.
    // Common pattern: owner(userId) + dateRange

    // For MVP Offline Phase 3:
    // We fetch everything and filter in memory.
    // Ideally we optimize this later with specific predicates.

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
