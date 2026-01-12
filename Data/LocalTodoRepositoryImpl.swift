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

  func readAll(query _: TodoQuery, source _: DataSource) async throws -> [Todo] {
    // Note: 'source' is ignored as this is strictly the local repository.

    // Construct predicate based on query filters
    // SwiftData #Predicate is strict. We cannot easily compose dynamic predicates yet without complex logic.
    // Simplifying: Fetch all and filter in memory for complex cases,
    // OR separate common patterns.
    // Common pattern: owner(userId) + dateRange

    // For MVP Offline Phase 3:
    // We fetch everything and filter in memory.
    // Ideally we optimize this later with specific predicates.

    let descriptor = FetchDescriptor<SDTodo>()
    let allSDTodos = try modelContext.fetch(descriptor)
    var todos = allSDTodos.map { $0.toDomain() }
//
//    // In-memory filtering
//    for filter in query.filters {
//      switch filter {
//      case .owner(let userId):
//        todos = todos.filter { $0.owner == userId }
//      case .owners(let userIds):
//        todos = todos.filter { userIds.contains($0.owner) }
//      case .dateRange(let range):
//        todos = todos.filter { range.contains($0.date) }
//      case .status(let status):
//        todos = todos.filter { $0.status == status }
//      }
//    }

    print(todos)
    return todos
  }
}
