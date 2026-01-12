//
//  PrivateTodoStore.swift
//  TodoMate
//
//  Created by hs on 07/02/25.
//

import Foundation
import Observation

@Observable
@MainActor
final class PrivateTodoStore {
  private let repository: TodoRepository

  var todos: [Date: [Todo]] = [:]
  var error: Error?

  init(container: CoreDIContainer) {
    repository = container.localTodoRepository
  }

  func loadTodos() async {
    do {
      // For now, load all local todos without filter
      // In future, we might filter by date range for efficiency
      let query = TodoQuery()
      let allTodos = try await repository.readAll(query: query, source: .cache)

      // Group by date
      let grouped = Dictionary(grouping: allTodos) { $0.date }
      todos = grouped
    } catch {
      self.error = error
      Log.error("Failed to load local todos: \(error)")
    }
  }

  func addTodo(_ todo: Todo) {
    Task {
      do {
        try await repository.create(todo)
        await loadTodos() // Reload to refresh UI
      } catch {
        self.error = error
        Log.error("Failed to create local todo: \(error)")
      }
    }
  }

  func updateTodo(_ todo: Todo) {
    Task {
      do {
        try await repository.update(todo)
        await loadTodos()
      } catch {
        self.error = error
        Log.error("Failed to update local todo: \(error)")
      }
    }
  }

  func deleteTodo(_ todoId: String) {
    Task {
      do {
        try await repository.delete(todoId)
        await loadTodos()
      } catch {
        self.error = error
        Log.error("Failed to delete local todo: \(error)")
      }
    }
  }
}

extension PrivateTodoStore {
  static var preview: PrivateTodoStore {
    PrivateTodoStore(container: .preview)
  }
}
