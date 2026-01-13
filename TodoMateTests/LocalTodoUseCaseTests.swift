//
//  LocalTodoUseCaseTests.swift
//  TodoMateTests
//
//  Created by agent on 1/13/26.
//

import Foundation
import Testing

@testable import TodoMate

@Suite("Local Todo UseCases Tests")
struct LocalTodoUseCaseTests {
  // MARK: - Mock Repository

  final class MockTodoRepository: TodoRepository {
    var todos: [Todo] = []
    var createCallCount = 0
    var updateCallCount = 0
    var deleteCallCount = 0
    var readCallCount = 0
    var lastQuery: TodoQuery?

    func create(_ todo: Todo) async throws {
      createCallCount += 1
      todos.append(todo)
    }

    func update(_ todo: Todo) async throws {
      updateCallCount += 1
      if let index = todos.firstIndex(where: { $0.id == todo.id }) {
        todos[index] = todo
      }
    }

    func delete(_ todoId: String) async throws {
      deleteCallCount += 1
      todos.removeAll { $0.id == todoId }
    }

    func readAll(query: TodoQuery, source _: DataSource) async throws -> [Todo] {
      readCallCount += 1
      lastQuery = query

      // Simple in-memory filter
      return todos.filter { todo in
        for filter in query.filters {
          switch filter {
          case let .dateRange(range):
            if !range.contains(todo.date) { return false }
          case let .owner(userId):
            if todo.owner != userId { return false }
          default: continue
          }
        }
        return true
      }
    }
  }

  // MARK: - Tests

  @Test("Create Local Todo")
  func createTodo() async throws {
    let repository = MockTodoRepository()
    let useCase = CreateLocalTodoUseCaseImpl(repository: repository)
    let todo = Todo(owner: "user1", content: "Test Todo", in: Date())

    try await useCase.run(todo)

    #expect(repository.createCallCount == 1)
    #expect(repository.todos.count == 1)
    #expect(repository.todos.first?.id == todo.id)
  }

  @Test("Read Local Todos by Date")
  func readTodosByDate() async throws {
    let repository = MockTodoRepository()
    let today = Date()
    let todo1 = Todo(owner: "user1", content: "Today Todo", in: today)
    let todo2 = Todo(
      owner: "user1", content: "Tomorrow Todo", in: today.addingTimeInterval(86400),
    )
    repository.todos = [todo1, todo2]

    let useCase = ReadLocalTodoUseCaseImpl(repository: repository, calendar: Calendar.current)

    // Run for today
    let result = try await useCase.run(date: today)

    #expect(repository.readCallCount == 1)
    #expect(result.count == 1)
    #expect(result.first?.id == todo1.id)

    // Verify query contained date range
    if let query = repository.lastQuery, case let .dateRange(range) = query.filters.first {
      // Roughly check range covers today
      let calendar = Calendar.current
      let start = calendar.startOfDay(for: today)
      #expect(range.lowerBound == start)
    }
  }

  @Test("Read Local Todos by Range")
  func readTodosByRange() async throws {
    let repository = MockTodoRepository()
    let today = Date()
    let nextWeek = today.addingTimeInterval(86400 * 7)
    let todo1 = Todo(owner: "user1", content: "Future Todo", in: nextWeek)
    repository.todos = [todo1]

    let useCase = ReadLocalTodoUseCaseImpl(repository: repository)

    let result = try await useCase.run(in: today ... nextWeek.addingTimeInterval(1))

    #expect(repository.readCallCount == 1)
    #expect(result.count > 0)
  }

  @Test("Update Local Todo")
  func updateTodo() async throws {
    let repository = MockTodoRepository()
    let todo = Todo(owner: "user1", content: "Original", in: Date())
    repository.todos = [todo]

    let useCase = UpdateLocalTodoUseCaseImpl(repository: repository)
    let updatedTodo = todo.withUpdatedContent("Updated")

    try await useCase.run(updatedTodo)

    #expect(repository.updateCallCount == 1)
    #expect(repository.todos.first?.content == "Updated")
  }

  @Test("Delete Local Todo")
  func deleteTodo() async throws {
    let repository = MockTodoRepository()
    let todo = Todo(owner: "user1", content: "To Delete", in: Date())
    repository.todos = [todo]

    let useCase = DeleteLocalTodoUseCaseImpl(repository: repository)

    try await useCase.run(todo.id)

    #expect(repository.deleteCallCount == 1)
    #expect(repository.todos.isEmpty)
  }
}
