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
  var selectedTodoId: String?

  private let calendar: Calendar
  private let observeTodosUseCase: ObserveTodosUseCase
  private let createTodoUseCase: CreateLocalTodoUseCase
  private let updateTodoUseCase: UpdateLocalTodoUseCase
  private let deleteTodoUseCase: DeleteLocalTodoUseCase

  init(
    calendar: Calendar = .current,
    observeTodosUseCase: ObserveTodosUseCase,
    createTodoUseCase: CreateLocalTodoUseCase,
    updateTodoUseCase: UpdateLocalTodoUseCase,
    deleteTodoUseCase: DeleteLocalTodoUseCase,
  ) {
    self.calendar = calendar
    self.observeTodosUseCase = observeTodosUseCase
    self.createTodoUseCase = createTodoUseCase
    self.updateTodoUseCase = updateTodoUseCase
    self.deleteTodoUseCase = deleteTodoUseCase
  }

  convenience init(container: CoreDIContainer) {
    self.init(
      calendar: container.calendar,
      observeTodosUseCase: container.observeTodosUseCase,
      createTodoUseCase: container.createLocalTodoUseCase,
      updateTodoUseCase: container.updateLocalTodoUseCase,
      deleteTodoUseCase: container.deleteLocalTodoUseCase,
    )
  }

  var days: [Date] {
    guard let monthInterval = calendar.dateInterval(of: .month, for: currentDate) else { return [] }
    let monthStart = monthInterval.start
    let weekday = calendar.component(.weekday, from: monthStart)
    let startOffset = weekday - 1
    let startDisplayDate = calendar.date(byAdding: .day, value: -startOffset, to: monthStart)!

    return (0 ..< 42).compactMap { dayOffset in
      calendar.date(byAdding: .day, value: dayOffset, to: startDisplayDate)
    }
  }

  var headerTitle: String {
    currentDate.formatted(.dateTime.month(.wide).year())
  }

  var weekdays: [String] {
    ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
  }

  func todos(for date: Date) -> [Todo] {
    todos.filter { calendar.isDate($0.date, inSameDayAs: date) }
  }

  func isCurrentMonth(_ date: Date) -> Bool {
    calendar.isDate(date, equalTo: currentDate, toGranularity: .month)
  }

  func isToday(_ date: Date) -> Bool {
    calendar.isDateInToday(date)
  }

  func nextMonth() {
    guard let newDate = calendar.date(byAdding: .month, value: 1, to: currentDate) else { return }
    currentDate = newDate
  }

  func previousMonth() {
    guard let newDate = calendar.date(byAdding: .month, value: -1, to: currentDate) else { return }
    currentDate = newDate
  }

  func goToday() {
    currentDate = Date()
  }

  func updateDate(of todo: Todo, to date: Date) {
    var updatedTodo = todo
    updatedTodo.date = calendar.startOfDay(for: date)
    updatedTodo.updatedAt = Date()
    update(updatedTodo)
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
