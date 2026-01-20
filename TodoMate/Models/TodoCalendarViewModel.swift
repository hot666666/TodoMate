//
//  TodoCalendarViewModel.swift
//  TodoMate
//
//  Created by agent on 1/11/26.
//

import Foundation
import Observation
import TodoMateDomain

@Observable
@MainActor
final class TodoCalendarViewModel {
  var todos: [Todo] = []
  var currentDate: Date = .init()

  private let observeTodosUseCase: ObserveTodosUseCase
  private let createTodoUseCase: CreateLocalTodoUseCase
  private let updateTodoUseCase: UpdateLocalTodoUseCase
  private let deleteTodoUseCase: DeleteLocalTodoUseCase

  init(
    observeTodosUseCase: ObserveTodosUseCase,
    createTodoUseCase: CreateLocalTodoUseCase,
    updateTodoUseCase: UpdateLocalTodoUseCase,
    deleteTodoUseCase: DeleteLocalTodoUseCase,
  ) {
    self.observeTodosUseCase = observeTodosUseCase
    self.createTodoUseCase = createTodoUseCase
    self.updateTodoUseCase = updateTodoUseCase
    self.deleteTodoUseCase = deleteTodoUseCase
  }

  convenience init(container: CoreDIContainer) {
    self.init(
      observeTodosUseCase: container.observeTodosUseCase,
      createTodoUseCase: container.createLocalTodoUseCase,
      updateTodoUseCase: container.updateLocalTodoUseCase,
      deleteTodoUseCase: container.deleteLocalTodoUseCase,
    )
  }

  var days: [Date] {
    let calendar = Calendar.current
    guard let monthInterval = calendar.dateInterval(of: .month, for: currentDate) else { return [] }
    let monthStart = monthInterval.start
    let weekday = calendar.component(.weekday, from: monthStart)
    let startOffset = weekday - 1
    let startDisplayDate = calendar.date(byAdding: .day, value: -startOffset, to: monthStart)!

    return (0 ..< 42).compactMap { dayOffset in
      calendar.date(byAdding: .day, value: dayOffset, to: startDisplayDate)
    }
  }

  func todos(for date: Date) -> [Todo] {
    let calendar = Calendar.current
    return todos.filter { calendar.isDate($0.date, inSameDayAs: date) }
  }

  func startObserving() async {
    guard let start = days.first, let end = days.last else { return }
    let range = start ... end

    // Observe changes for the current date range
    for await newTodos in observeTodosUseCase.execute(dateRange: range) {
      todos = newTodos
    }
  }

  func update(_ todo: Todo) {
    Task {
      do {
        try await updateTodoUseCase.run(todo)
      } catch {
        print("Failed to update todo: \(error)")
      }
    }
  }

  func duplicate(_ todo: Todo) {
    var newTodo = Todo.copy(from: todo)
    newTodo.detail = ""

    Task {
      do {
        try await createTodoUseCase.run(newTodo)
      } catch {
        print("Failed to duplicate todo: \(error)")
      }
    }
  }

  func delete(_ todo: Todo) {
    Task {
      do {
        try await deleteTodoUseCase.run(todo.id)
      } catch {
        print("Failed to delete todo: \(error)")
      }
    }
  }
}

extension TodoCalendarViewModel {
  static var preview: TodoCalendarViewModel {
    TodoCalendarViewModel(container: .preview)
  }
}
