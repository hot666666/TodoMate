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

  final class MockTodoRepository: TodoRepository {
    var todos: [Todo] = []

    func create(_ todo: Todo) async throws {
      todos.append(todo)
    }

    func update(_ todo: Todo) async throws {
      if let index = todos.firstIndex(where: { $0.id == todo.id }) {
        todos[index] = todo
      }
    }

    func delete(_ todoId: String) async throws {
      todos.removeAll { $0.id == todoId }
    }

    func readAll(query: TodoQuery, source _: DataSource) async throws -> [Todo] {
      todos.filter { todo in
        for filter in query.filters {
          switch filter {
          case let .dateRange(range):
            // Logic to mimic strict filtering.
            // Store logic: sends startOfDay...endOfDay
            if !range.contains(todo.date) { return false }
          case .owner:
            // Repository was told to ignore owner, but in-memory mock can implement or ignore.
            // For this test, we care about date.
            continue
          default: continue
          }
        }
        return true
      }
    }
  }

  @Test("Load only Today's todos")
  func loadTodos_filtersToday() async {
    // Given
    let repository = MockTodoRepository()
    let store = PrivateTodoStore(repository: repository)

    let calendar = Calendar.current
    let today = Date()
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
    let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

    let todoToday = Todo(owner: "me", content: "Today", in: today)
    let todoYesterday = Todo(owner: "me", content: "Yesterday", in: yesterday)
    let todoTomorrow = Todo(owner: "me", content: "Tomorrow", in: tomorrow)

    repository.todos = [todoYesterday, todoToday, todoTomorrow]

    // When
    await store.loadTodos()

    // Then
    #expect(store.todos.count == 1)
    #expect(store.todos.first?.id == todoToday.id)
  }

  @Test("Add Todo refreshes list")
  func addTodo_refreshesList() async {
    // Given
    let repository = MockTodoRepository()
    let store = PrivateTodoStore(repository: repository)
    let todo = Todo(owner: "me", content: "New Todo", in: Date())

    // When
    store.addTodo(todo)

    // Wait for async task in store.addTodo (fire and forget)
    // Since it's unstructured concurrency, we need a small delay or check
    // Ideally store should expose async API, but it follows current pattern.
    // We can wait a bit
    try? await Task.sleep(for: .milliseconds(100))

    // Then
    #expect(repository.todos.count == 1)
    #expect(store.todos.count == 1)
    #expect(store.todos.first?.content == "New Todo")
  }

  @Test("Load Calendar Todos filters by month")
  func loadCalendarTodos_filtersMonth() async {
    // Given
    let repository = MockTodoRepository()
    let store = PrivateTodoStore(repository: repository)

    let calendar = Calendar.current

    // Create dates for current month, next month, prev month
    // Assuming 'today' is not on the edge of month for simplicity of test,
    // or just constructing explicit dates.

    // Let's force a specific date like 2024-01-15
    var components = DateComponents()
    components.year = 2024
    components.month = 1
    components.day = 15
    let midJan = calendar.date(from: components)!

    let jan1 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
    let jan31 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 31))!
    let feb1 = calendar.date(from: DateComponents(year: 2024, month: 2, day: 1))!
    let dec31 = calendar.date(from: DateComponents(year: 2023, month: 12, day: 31))!

    let todoMidJan = Todo(owner: "me", content: "Jan 15", in: midJan)
    let todoJan1 = Todo(owner: "me", content: "Jan 1", in: jan1)
    let todoJan31 = Todo(owner: "me", content: "Jan 31", in: jan31)
    let todoFeb1 = Todo(owner: "me", content: "Feb 1", in: feb1)
    let todoDec31 = Todo(owner: "me", content: "Dec 31", in: dec31)

    repository.todos = [todoDec31, todoJan1, todoMidJan, todoJan31, todoFeb1]

    // When
    await store.loadCalendarTodos(for: midJan)

    // Then
    // Should include Jan 1, Jan 15, Jan 31 (3 items)
    // Should exclude Dec 31, Feb 1
    #expect(store.calendarTodos.count == 3)
    let contents = store.calendarTodos.map(\.content).sorted()
    #expect(contents == ["Jan 1", "Jan 15", "Jan 31"])
  }
}
