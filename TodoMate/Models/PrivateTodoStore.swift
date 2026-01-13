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
  private let createUseCase: CreateLocalTodoUseCase
  private let readUseCase: ReadLocalTodoUseCase
  private let updateUseCase: UpdateLocalTodoUseCase
  private let deleteUseCase: DeleteLocalTodoUseCase

  var todos: [Todo] = []
  var calendarTodos: [Todo] = []
  var error: Error?

  init(
    createUseCase: CreateLocalTodoUseCase,
    readUseCase: ReadLocalTodoUseCase,
    updateUseCase: UpdateLocalTodoUseCase,
    deleteUseCase: DeleteLocalTodoUseCase,
  ) {
    self.createUseCase = createUseCase
    self.readUseCase = readUseCase
    self.updateUseCase = updateUseCase
    self.deleteUseCase = deleteUseCase
  }

  convenience init(container: CoreDIContainer) {
    self.init(
      createUseCase: container.createLocalTodoUseCase,
      readUseCase: container.readLocalTodoUseCase,
      updateUseCase: container.updateLocalTodoUseCase,
      deleteUseCase: container.deleteLocalTodoUseCase,
    )
  }

  func loadTodos() async {
    do {
      let today = Date()
      let todos = try await readUseCase.run(date: today)
      self.todos = todos
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

      let monthTodos = try await readUseCase.run(in: startOfMonth ... endOfDay)
      calendarTodos = monthTodos
    } catch {
      self.error = error
      Log.error("Failed to load calendar todos: \(error)")
    }
  }

  func addTodo(_ todo: Todo) {
    Task {
      do {
        try await createUseCase.run(todo)
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
        try await updateUseCase.run(todo)
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
        try await deleteUseCase.run(todoId)
        await loadTodos()
        // Ideally we know the date, but for now we might need to refresh current calendar view context
        // This is a limitation of not passing the deleted Todo object or date.
        // We'll rely on View's onAppear or simple refresh.
      } catch {
        self.error = error
        Log.error("Failed to delete local todo: \(error)")
      }
    }
  }

  func deleteTodo(_ todo: Todo) {
    Task {
      do {
        try await deleteUseCase.run(todo.id)
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
