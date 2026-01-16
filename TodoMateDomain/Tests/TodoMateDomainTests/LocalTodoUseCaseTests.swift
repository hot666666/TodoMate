//
//  LocalTodoUseCaseTests.swift
//  TodoMateDomainTests
//
//  Created by agent on 1/13/26.
//

import Foundation
import Testing

@testable import TodoMateDomain

@Suite("Local Todo UseCases Tests")
struct LocalTodoUseCaseTests {
  @Test("Create Local Todo")
  func createTodo() async throws {
    let repository = InMemoryTodoRepository()
    let useCase = CreateLocalTodoUseCaseImpl(repository: repository)
    let todo = Todo(owner: "user1", content: "Test Todo", in: Date())

    try await useCase.run(todo)

    let count = await repository.createCallCount
    let repoTodosCount = await repository.todos.count
    let firstId = await repository.todos.first?.id

    #expect(count == 1)
    #expect(repoTodosCount == 1)
    #expect(firstId == todo.id)
  }

  @Test("Read Local Todos by Date")
  func readTodosByDate() async throws {
    let repository = InMemoryTodoRepository()
    let today = Date()
    let todo1 = Todo(owner: "user1", content: "Today Todo", in: today)
    let todo2 = Todo(
      owner: "user1", content: "Tomorrow Todo", in: today.addingTimeInterval(86400),
    )
    await repository.setTodos([todo1, todo2])

    let useCase = ReadLocalTodoUseCaseImpl(repository: repository, calendar: Calendar.current)

    // Run for today
    let result = try await useCase.run(date: today)

    let readCount = await repository.readCallCount
    let firstId = await repository.todos.first?.id

    #expect(readCount == 1)
    #expect(result.count == 1)
    #expect(result.first?.id == firstId)

    // Verify query contained date range
    if let query = await repository.lastQuery, case let .dateRange(range) = query.filters.first {
      // Roughly check range covers today
      let calendar = Calendar.current
      let start = calendar.startOfDay(for: today)
      #expect(range.lowerBound == start)
    }
  }

  @Test("Read Local Todo by ID")
  func readTodoById() async throws {
    let repository = InMemoryTodoRepository()
    let todo = Todo(owner: "user1", content: "Target Todo", in: Date())
    await repository.setTodos([todo])

    let useCase = ReadLocalTodoUseCaseImpl(repository: repository)

    let result = try await useCase.run(id: todo.id)

    #expect(result?.id == todo.id)
    #expect(result?.content == "Target Todo")

    // Verify non-existent
    let nonExistent = try await useCase.run(id: "non-existent")
    #expect(nonExistent == nil)
  }

  @Test("Read Local Todos by Range")
  func readTodosByRange() async throws {
    let repository = InMemoryTodoRepository()
    let today = Date()
    let nextWeek = today.addingTimeInterval(86400 * 7)
    let todo1 = Todo(owner: "user1", content: "Future Todo", in: nextWeek)
    await repository.setTodos([todo1])

    let useCase = ReadLocalTodoUseCaseImpl(repository: repository)

    let result = try await useCase.run(in: today ... nextWeek.addingTimeInterval(1))

    let readCount = await repository.readCallCount
    #expect(readCount == 1)
    #expect(result.count > 0)
  }

  @Test("Update Local Todo")
  func updateTodo() async throws {
    let repository = InMemoryTodoRepository()
    let todo = Todo(owner: "user1", content: "Original", in: Date())
    await repository.setTodos([todo])

    let useCase = UpdateLocalTodoUseCaseImpl(repository: repository)
    let updatedTodo = todo.withUpdatedContent("Updated")

    try await useCase.run(updatedTodo)

    let updateCount = await repository.updateCallCount
    let firstContent = await repository.todos.first?.content

    #expect(updateCount == 1)
    #expect(firstContent == "Updated")
  }

  @Test("Delete Local Todo")
  func deleteTodo() async throws {
    let repository = InMemoryTodoRepository()
    let todo = Todo(owner: "user1", content: "To Delete", in: Date())
    await repository.setTodos([todo])

    let useCase = DeleteLocalTodoUseCaseImpl(repository: repository)

    try await useCase.run(todo.id)

    let deleteCount = await repository.deleteCallCount
    let isEmpty = await repository.todos.isEmpty

    #expect(deleteCount == 1)
    #expect(isEmpty)
  }
}
