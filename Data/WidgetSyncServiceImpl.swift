//
//  WidgetSyncServiceImpl.swift
//  Todo
//
//  Created by Claude on 6/27/25.
//

import SwiftData
import WidgetKit

final class SwiftDataWidgetSyncService: WidgetSyncService {
  private let todoRepository: TodoRepository
  private let modelContext: ModelContext

  init(
    todoRepository: TodoRepository,
    modelContext: ModelContext,
  ) {
    self.todoRepository = todoRepository
    self.modelContext = modelContext
  }

  func sync(with todos: [Todo]) async {
    let inProgressTodos = todos.filter { $0.status == .inProgress }
    updateWidgetTodos(with: inProgressTodos)
    WidgetCenter.shared.reloadAllTimelines()
    print("[WidgetSyncUseCase] - Synced \(todos.count) todos")
  }

  func clearAllWidgetTodos() async {
    updateWidgetTodos(with: [])
    WidgetCenter.shared.reloadAllTimelines()
    print("[WidgetSyncUseCase] - Cleared all widget todos")
  }

  // MARK: - Private Methods

  private func updateWidgetTodos(with todos: [Todo]) {
    do {
      try modelContext.delete(model: WidgetTodo.self)

      for todo in todos {
        let widgetTodo = WidgetTodo.from(todo)
        modelContext.insert(widgetTodo)
      }

      try modelContext.save()
    } catch {
      print("[WidgetSyncUseCase] - Failed to update widget todos: \(error)")
    }
  }
}

// MARK: - Stub Implementation

final class StubWidgetSyncService: WidgetSyncService {
  func sync(with _: [Todo]) async {
    print("[StubWidgetSyncUseCase] - Sync completed (stub)")
  }

  func clearAllWidgetTodos() async {
    print("[StubWidgetSyncUseCase] - Clear all widget todos completed (stub)")
  }
}
