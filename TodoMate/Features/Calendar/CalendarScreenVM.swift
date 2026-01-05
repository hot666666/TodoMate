//
//  CalendarScreenVM.swift
//  Todo
//
//  Created by hs on 7/5/25.
//

import SwiftUI

@Observable
final class CalendarScreenVM {
  private let createTodoUseCase: CreateTodoUseCase
  private let readMonthlyTodoUseCase: ReadMonthlyTodoUseCase
  private let updateTodoUseCase: UpdateTodoUseCase
  private let deleteTodoUseCase: DeleteTodoUseCase
  private let calendarDayService: CalendarDayService

  private(set) var isLoading: Bool = false
  private(set) var todosInMonth: [Date: [Todo]] = [:]
  func todosForDay(_ date: Date) -> [Todo] {
    todosInMonth[date.startOfDay] ?? []
  }

  init(container: DIContainer) {
    createTodoUseCase = container.createTodoUseCase
    readMonthlyTodoUseCase = container.readMonthlyTodoUseCase
    updateTodoUseCase = container.updateTodoUseCase
    deleteTodoUseCase = container.deleteTodoUseCase
    calendarDayService = container.calendarDayService
  }

  @MainActor
  func load(userId: String, useCache: Bool = false) async {
    defer { isLoading = false }
    isLoading = true
    do {
      let range = calendarDayService.getRange(for: currentDate)
      let todos = try await readMonthlyTodoUseCase.run(for: userId, range: range, useCache: useCache)
      todosInMonth = Dictionary(grouping: todos, by: { $0.date.startOfDay })
    } catch {
      print("[CalendarScreenScreenVM] - Failed to load monthly todos: \(error)")
    }
  }

  func refresh(userId: String) async {
    await load(userId: userId, useCache: true)
  }

  func addTodo(_ todo: Todo, for userId: String) {
    do {
      try createTodoUseCase.run(for: userId, todo)
      Task {
        await refresh(userId: userId)
      }
    } catch {
      print("[CalendarScreenScreenVM] - Failed to add todo: \(error)")
    }
  }

  func copyTodo(_ todo: Todo, for userId: String) {
    do {
      let now = Date()
      let newTodo = Todo(
        content: todo.content,
        status: .todo,
        detail: todo.detail,
        date: todo.date,
        createdAt: now,
        updatedAt: now,
        owner: todo.owner,
      )
      try createTodoUseCase.run(for: userId, newTodo)

      Task {
        await refresh(userId: userId)
      }
    } catch {
      print("[CalendarScreenScreenVM] - Failed to copy todo: \(error)")
    }
  }

  func deleteTodo(_ todo: Todo, for userId: String) {
    Task {
      do {
        try await deleteTodoUseCase.run(for: userId, todo)
        await refresh(userId: userId)
      } catch {
        print("[CalendarScreenScreenVM] - Failed to delete todo: \(error)")
      }
    }
  }

  func moveTodo(todoId: String, from sourceDate: Date, to targetDate: Date, for userId: String) {
    do {
      let normalizedSourceDate = sourceDate.startOfDay
      let normalizedTargetDate = targetDate.startOfDay

      guard var sourceTodos = todosInMonth[normalizedSourceDate],
            let todoIndex = sourceTodos.firstIndex(where: { $0.id == todoId })
      else {
        print("[CalendarScreenScreenVM] - Failed to find todo with id: \(todoId)")
        return
      }

      let todoToMove = sourceTodos[todoIndex]
      var updatedTodo = todoToMove
      updatedTodo.date = normalizedTargetDate
      updatedTodo.updatedAt = Date()

      try updateTodoUseCase.run(for: userId, updatedTodo)

      sourceTodos.remove(at: todoIndex)
      if sourceTodos.isEmpty {
        todosInMonth.removeValue(forKey: normalizedSourceDate)
      } else {
        todosInMonth[normalizedSourceDate] = sourceTodos
      }

      var targetTodos = todosInMonth[normalizedTargetDate] ?? []
      targetTodos.append(updatedTodo)
      todosInMonth[normalizedTargetDate] = targetTodos

    } catch {
      print("[CalendarScreenScreenVM] - Failed to move todo: \(error)")
    }
  }

  /// 기준은 날의 00:00:00이 되어야함
  var currentDate: Date = .now.startOfDay

  func moveToNextMonth(userId: String) {
    currentDate = calendarDayService.moveMonth(of: currentDate, by: 1)
    Task {
      await load(userId: userId)
    }
  }

  func moveToPrevMonth(userId: String) {
    currentDate = calendarDayService.moveMonth(of: currentDate, by: -1)
    Task {
      await load(userId: userId)
    }
  }

  func moveToCurrMonth(userId: String) {
    currentDate = .now.startOfDay
    Task {
      await load(userId: userId)
    }
  }

  var calendarRowCount: Int {
    let daysInCalendar = calendarDayService.getRange(for: currentDate)
    let daysCount = calendarDayService.countDays(in: daysInCalendar)
    return max(1, Int(ceil(Double(daysCount) / 7.0)))
  }

  var calendarDays: [CalendarDay] {
    calendarDayService.getCalendarDays(in: currentDate)
  }
}
