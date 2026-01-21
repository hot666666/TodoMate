//
//  TodoCalendarViewModel.swift
//  TodoMate
//
//  Created by agent on 1/11/26.
//

import Foundation
import Observation
import SimpleOverlaySystem
import SwiftUI
import TodoMateDomain

@Observable
@MainActor
final class TodoCalendarViewModel {
  static let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

  var todos: [Todo] = [] {
    didSet {
      rebuildTodosByDate()
      updateSelectedDateTodos()
    }
  }

  var currentDate: Date = .init()
  var selectedDate: Date? {
    didSet { updateSelectedDateTodos() }
  }

  var selectedTodoId: String?
  private(set) var selectedDateTodos: [Todo] = []
  private(set) var todosByDate: [Date: [Todo]] = [:]

  private func rebuildTodosByDate() {
    todosByDate = Dictionary(grouping: todos) { calendar.startOfDay(for: $0.date) }
  }

  private func updateSelectedDateTodos() {
    guard let date = selectedDate else {
      selectedDateTodos = []
      return
    }
    selectedDateTodos = todosByDate[calendar.startOfDay(for: date)] ?? []
  }

  // Weak reference to avoid retain cycles (ViewModel -> OverlayManager -> View -> ViewModel)
  weak var overlay: OverlayManager?

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
    todosByDate[calendar.startOfDay(for: date)] ?? []
  }

  func dayString(from date: Date) -> String {
    "\(calendar.component(.day, from: date))"
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
    selectedTodoId = nil

    guard let start = days.first, let end = days.last else { return }
    let range = start ... end

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

  // MARK: - Overlay Actions

  func presentTodoSheet(for todo: Todo) {
    overlay?.presentCentered(
      id: .todoSheet,
      backdropOpacity: 0,
      offset: CGPoint(x: 0, y: -120),
    ) {
      TodoSheet(editableTodo: EditableTodo(from: todo))
    }
  }

  func presentDayTodoList(for date: Date) {
    selectDate(date)
    overlay?.presentCentered(backdropOpacity: 0) {
      DayTodoList(date: date)
        .environment(self)
    }
  }

  // MARK: - View Helpers

  func maxVisibleItems(for height: CGFloat) -> Int {
    let titleHeight: CGFloat = 20
    let itemHeight: CGFloat = 24 // Compact card height
    let availableHeight = height - titleHeight - 4
    return max(1, Int(availableHeight / itemHeight))
  }

  func updateStatus(_ todo: Todo, to status: TodoStatus) {
    var updated = todo
    updated.status = status
    update(updated)
  }

  @discardableResult
  func handleDrop(todos: [Todo], to date: Date) -> Bool {
    guard let todo = todos.first else { return false }
    updateDate(of: todo, to: date)
    return true
  }

  @discardableResult
  func handleStatusDrop(todos items: [Todo], to status: TodoStatus) -> Bool {
    guard let todo = items.first else { return false }
    if todo.status != status {
      updateStatus(todo, to: status)
    }
    return true
  }

  func selectDate(_ date: Date) {
    selectedDate = date
  }
}

extension TodoCalendarViewModel {
  static var preview: TodoCalendarViewModel {
    TodoCalendarViewModel(container: .preview)
  }
}
