//
//  TodoCalendarViewModel.swift
//  TodoMate
//
//  Created by hs on 2/2/25.
//

import SwiftUI

@Observable
class TodoCalendarViewModel {
  private let calendar: Calendar = .current
  private let todoService: TodoServiceType
  private var isDropTargeted: Bool = false

  @ObservationIgnored let isMine: Bool
  @ObservationIgnored let user: User
  @ObservationIgnored let dismiss: () -> Void

  var todos: [Date: [Todo]] = [:]
  var currentDate: Date = .now
  var calendarDays: [CalendarDay] = []
  var isLoading: Bool = false

  init(container: DIContainer, user: User, isMine: Bool, dismiss: @escaping () -> Void) {
    todoService = container.todoService
    self.user = user
    self.isMine = isMine
    self.dismiss = dismiss

    updateCalendarDays()
  }
}

extension TodoCalendarViewModel {
  // MARK: - Drag & Drop

  func setDropTarget(status: Bool) {
    isDropTargeted = status
  }

  func onDrop(data: [TodoTransferData], to newDate: Date) -> Bool {
    // 유효한 데이터인지 확인
    guard isMine, let oldTodoData = data.first else {
      return false
    }

    let oldDate = calendar.startOfDay(for: oldTodoData.date)
    let newDate = calendar.startOfDay(for: newDate)

    // 기존 데이터가 존재하는지 확인
    guard
      let oldTodos = todos[oldDate],
      let oldTodo = oldTodos.first(where: { $0.fid == oldTodoData.fid })
    else {
      return false
    }

    // 업데이트
    var newTodo = oldTodo
    newTodo.date = newDate
    do {
      try todoService.update(from: oldTodo, with: newTodo)
    } catch {
      return false
    }

    todos[oldDate, default: []].removeAll { $0.fid == oldTodo.fid }
    todos[newDate, default: []].append(newTodo)

    return true
  }
}

extension TodoCalendarViewModel {
  // MARK: - update current dates

  func moveMonth(by value: Int) async {
    let updatedDate = calendar.addMonths(value, to: currentDate)!
    currentDate = updatedDate
    updateCalendarDays()

    await fetch()
  }

  func currentMonth() async {
    currentDate = .now
    updateCalendarDays()

    await fetch()
  }
}

extension TodoCalendarViewModel {
  @MainActor
  func fetch() async {
    defer { isLoading = false }

    let startDateOfMonth = calendar.startOfMonth(for: currentDate)
    let startDate = calendar.addDays(
      -calendar.component(.weekday, from: startDateOfMonth) + 1,
      to: startDateOfMonth
    )
    let endDate = calendar.addDays(41, to: startDate).addingTimeInterval(-1)

    isLoading = true
    todos = await todoService.fetchMonth(userId: user.uid, startDate: startDate, endDate: endDate)
  }

  @MainActor
  func create(date: Date) async {
    guard isMine else { return }
    defer { isLoading = false }

    let todo: Todo = .init(date: date, uid: user.uid)

    isLoading = true
    guard
      let createdTodo = await todoService.create(from: todo),
      !createdTodo.fid.isEmpty
    else {
      print("Failed to create todo")
      return
    }

    let todoDate = calendar.startOfDay(for: createdTodo.date)
    todos[todoDate, default: []].append(createdTodo)
  }

  @MainActor
  func copy(_ todo: Todo) async {
    guard isMine else { return }
    defer { isLoading = false }

    let copiedTodo: Todo = .copy(from: todo)

    isLoading = true
    guard
      let createdTodo = await todoService.create(from: copiedTodo),
      !createdTodo.fid.isEmpty
    else {
      print("Failed to create todo")
      return
    }

    let todoDate = calendar.startOfDay(for: createdTodo.date)
    todos[todoDate, default: []].append(createdTodo)
  }

  func update(oldDate: Date, newTodo: Todo) {
    guard isMine else { return }

    // TODO: - Todo 엔티티 update 로직 사용(상태 조건)
    todoService.update(newTodo)

    let oldDate = calendar.startOfDay(for: oldDate)
    let newDate = calendar.startOfDay(for: newTodo.date)
    guard
      var todosInDate = todos[newDate],
      let index = todosInDate.firstIndex(where: { $0.fid == newTodo.fid })
    else {
      /// 현재 캘린더 뷰에 없는 날짜로 이동한 경우, 기존 날짜의 데이터를 삭제만 수행
      todos[oldDate, default: []].removeAll { $0.fid == newTodo.fid }
      return
    }

    if oldDate == newDate {
      todosInDate[index] = newTodo
      todos[newDate] = todosInDate
    } else {
      todos[oldDate, default: []].removeAll { $0.fid == newTodo.fid }
      todos[newDate, default: []].append(newTodo)
    }
  }

  func remove(_ todo: Todo) {
    guard isMine else { return }

    todoService.remove(todo)

    let todoDate = calendar.startOfDay(for: todo.date)

    todos[todoDate, default: []].removeAll { $0.fid == todo.fid }
  }
}

extension TodoCalendarViewModel {
  private func updateCalendarDays() {
    let startOfMonth = calendar.startOfMonth(for: currentDate)
    let startDayInPreviousMonth = calendar.addDays(
      -calendar.component(.weekday, from: startOfMonth) + 1,
      to: startOfMonth
    )

    var days: [CalendarDay] = []

    for dayOffset in 0 ..< 42 {
      let date = calendar.addDays(dayOffset, to: startDayInPreviousMonth)

      let monthType: CalendarMonthType
      if calendar.isDate(date, equalTo: currentDate, toGranularity: .month) {
        monthType = .curr
      } else if date < startOfMonth {
        monthType = .prev
      } else {
        monthType = .next
      }

      let dateType: CalendarDateType
      if calendar.isDateInToday(date) {
        dateType = .today
      } else {
        dateType = .default
      }

      days.append(CalendarDay(id: dayOffset, date: date, monthType: monthType, dateType: dateType))
    }

    calendarDays = days
  }
}
