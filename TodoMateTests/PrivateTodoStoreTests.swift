//
//  PrivateTodoStoreTests.swift
//  TodoMateTests
//
//  Created by agent on 1/12/26.
//

import Foundation
import Testing

@testable import TodoMate

@Suite("PrivateTodoStore Unit Tests")
@MainActor
struct PrivateTodoStoreTests {
  // MARK: - Mock Repository

  // MARK: - Mock UseCases

  final class MockCreateUseCase: CreateLocalTodoUseCase {
    var runHandler: ((Todo) -> Void)?
    func run(_ todo: Todo) async throws { runHandler?(todo) }
  }

  final class MockReadUseCase: ReadLocalTodoUseCase {
    var todos: [Todo] = []
    func run(date: Date) async throws -> [Todo] {
      // Filter by date for "today" logic if needed, or just return set todos
      // mimicing the behavior of ReadLocalTodoUseCaseImpl
      let calendar = Calendar.current
      return todos.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func run(in range: ClosedRange<Date>) async throws -> [Todo] {
      todos.filter { range.contains($0.date) }
    }
  }

  final class MockUpdateUseCase: UpdateLocalTodoUseCase {
    var runHandler: ((Todo) -> Void)?
    func run(_ todo: Todo) async throws { runHandler?(todo) }
  }

  final class MockDeleteUseCase: DeleteLocalTodoUseCase {
    var runHandler: ((String) -> Void)?
    func run(_ todoId: String) async throws { runHandler?(todoId) }
  }

  @Test("Load only Today's todos")
  func loadTodos_filtersToday() async {
    // Given
    let createUC = MockCreateUseCase()
    let readUC = MockReadUseCase()
    let updateUC = MockUpdateUseCase()
    let deleteUC = MockDeleteUseCase()

    let store = PrivateTodoStore(
      createUseCase: createUC,
      readUseCase: readUC,
      updateUseCase: updateUC,
      deleteUseCase: deleteUC,
    )

    let calendar = Calendar.current
    let today = Date()
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
    let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

    let todoToday = Todo(owner: "me", content: "Today", in: today)
    let todoYesterday = Todo(owner: "me", content: "Yesterday", in: yesterday)
    let todoTomorrow = Todo(owner: "me", content: "Tomorrow", in: tomorrow)

    readUC.todos = [todoYesterday, todoToday, todoTomorrow]

    // When
    await store.loadTodos()

    // Then
    #expect(store.todos.count == 1)
    #expect(store.todos.first?.id == todoToday.id)
  }

  @Test("Add Todo refreshes list")
  func addTodo_refreshesList() async {
    // Given
    let createUC = MockCreateUseCase()
    let readUC = MockReadUseCase()
    let updateUC = MockUpdateUseCase()
    let deleteUC = MockDeleteUseCase()

    let store = PrivateTodoStore(
      createUseCase: createUC,
      readUseCase: readUC,
      updateUseCase: updateUC,
      deleteUseCase: deleteUC,
    )

    let todo = Todo(owner: "me", content: "New Todo", in: Date())

    var created = false
    createUC.runHandler = { _ in created = true }

    // Simulate data update after create
    readUC.todos = [todo]

    // When
    store.addTodo(todo)

    // Wait slightly for async task
    try? await Task.sleep(for: .milliseconds(100))

    // Then
    #expect(created)
    #expect(store.todos.count == 1)
    #expect(store.todos.first?.content == "New Todo")
  }

  @Test("Load Calendar Todos filters by month")
  func loadCalendarTodos_filtersMonth() async {
    // Given
    let createUC = MockCreateUseCase()
    let readUC = MockReadUseCase()
    let updateUC = MockUpdateUseCase()
    let deleteUC = MockDeleteUseCase()

    let store = PrivateTodoStore(
      createUseCase: createUC,
      readUseCase: readUC,
      updateUseCase: updateUC,
      deleteUseCase: deleteUC,
    )

    let calendar = Calendar.current
    // Mid Jan 2024
    let midJan = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15))!

    let jan1 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
    let jan31 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 31))!
    let feb1 = calendar.date(from: DateComponents(year: 2024, month: 2, day: 1))!
    let dec31 = calendar.date(from: DateComponents(year: 2023, month: 12, day: 31))!

    let todoMidJan = Todo(owner: "me", content: "Jan 15", in: midJan)
    let todoJan1 = Todo(owner: "me", content: "Jan 1", in: jan1)
    let todoJan31 = Todo(owner: "me", content: "Jan 31", in: jan31)
    let todoFeb1 = Todo(owner: "me", content: "Feb 1", in: feb1)
    let todoDec31 = Todo(owner: "me", content: "Dec 31", in: dec31)

    readUC.todos = [todoDec31, todoJan1, todoMidJan, todoJan31, todoFeb1]

    // When
    await store.loadCalendarTodos(for: midJan)

    // Then
    // Expecting logic inside ReadLocalTodoUseCase to handle range,
    // and MockReadUseCase receives a range and filters.
    // The Store calculates range (Start of Month to End of Month)

    #expect(store.calendarTodos.count == 3)
    let contents = store.calendarTodos.map(\.content).sorted()
    #expect(contents == ["Jan 1", "Jan 15", "Jan 31"])
  }
}
