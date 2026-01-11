//
//  LocalTodoRepositoryImpl.swift
//  TodoMate
//
//  Created by hs on 07/02/25.
//

import Foundation
import SwiftData

final class LocalTodoRepositoryImpl: TodoRepository {
  private let modelContext: ModelContext

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }

  func create(_ todo: Todo) throws {
    let sdTodo = SDTodo(from: todo)
    modelContext.insert(sdTodo)
  }

  func update(_ todo: Todo) throws {
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
    } else {
      // If not found, should we throw or insert? Domain logic usually expects update to fail if not found,
      // but for robustness we might log warning.
      // throw TodoRepositoryError.notFound
      // For now, let's just insert it as fallback or do nothing.
      // Safe choice: do nothing but log, or throw.
      // Since protocol uses `throws`, let's just leave it silent or insert?
      // Revisit requirement. For now, treating as must-exist.
    }
  }

  func delete(_ todoId: String) async throws {
    let descriptor = FetchDescriptor<SDTodo>(predicate: #Predicate { $0.id == todoId })
    if let existing = try modelContext.fetch(descriptor).first {
      modelContext.delete(existing)
    }
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

    let descriptor = FetchDescriptor<SDTodo>()
    let allSDTodos = try modelContext.fetch(descriptor)
    var todos = allSDTodos.map { $0.toDomain() }

    // In-memory filtering
    for filter in query.filters {
      switch filter {
      case let .owner(userId):
        todos = todos.filter { $0.owner == userId }
      case let .owners(userIds):
        todos = todos.filter { userIds.contains($0.owner) }
      case let .dateRange(range):
        todos = todos.filter { range.contains($0.date) }
      case let .status(status):
        todos = todos.filter { $0.status == status }
      }
    }

    return todos
  }
}
