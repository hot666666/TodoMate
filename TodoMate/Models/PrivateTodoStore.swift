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

  var todos: [Todo] = []
  var calendarTodos: [Todo] = []
  var error: Error?

  init(repository: TodoRepository) {
    self.repository = repository
  }

  convenience init(container: CoreDIContainer) {
    self.init(repository: container.localTodoRepository)
  }

  func loadTodos() async {
    do {
      let calendar = Calendar.current
      let today = Date()
      let startOfDay = calendar.startOfDay(for: today)
      guard let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: today)
      else { return }

      let query = TodoQuery().dateRange(startOfDay ... endOfDay)
      let todayTodos = try await repository.readAll(query: query, source: .cache)
      todos = todayTodos
    } catch {
      self.error = error
      Log.error("Failed to load local todos: \(error)")
    }
  }

  func loadCalendarTodos(for date: Date) async {
    do {
      let calendar = Calendar.current
      guard
        let startOfMonth = calendar.date(
          from: calendar.dateComponents([.year, .month], from: date)),
        let endOfMonth = calendar.date(
          byAdding: DateComponents(month: 1, day: -1), to: startOfMonth,
        ),
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endOfMonth)
      else { return }

      let query = TodoQuery().dateRange(startOfMonth ... endOfDay)
      let monthTodos = try await repository.readAll(query: query, source: .cache)
      calendarTodos = monthTodos
    } catch {
      self.error = error
      Log.error("Failed to load calendar todos: \(error)")
    }
  }

  func addTodo(_ todo: Todo) {
    Task {
      do {
        try await repository.create(todo)
        await loadTodos()
        // We reload calendar for the todo's date just in case it's currently viewed
        await loadCalendarTodos(for: todo.date)
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
        await loadCalendarTodos(for: todo.date)
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
        // Ideally we know the date, but for now we might need to refresh current calendar view context
        // This is a limitation of not passing the deleted Todo object or date.
        // We'll rely on View's onAppear or simple refresh.
        // Or overload delete to take date?
        // For now, let's just accept that delete might not update calendar immediately if we don't know date.
        // But `loadTodos` updates Today.
        // Let's create a `deleteTodo(_ todo: Todo)` overload or just refresh a default date?
        // Actually, if we delete, we should probably refresh the currently viewed month if possible.
        // Storing 'currentCalendarDate' in Store is an option.
      } catch {
        self.error = error
        Log.error("Failed to delete local todo: \(error)")
      }
    }
  }

  func deleteTodo(_ todo: Todo) {
    Task {
      do {
        try await repository.delete(todo.id)
        await loadTodos()
        await loadCalendarTodos(for: todo.date)
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
