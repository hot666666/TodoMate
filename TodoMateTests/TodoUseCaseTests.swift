//
//  TodoUseCaseTests.swift
//  TodoMateTests
//
//  Created by agent on 1/8/26.
//

import Foundation
import Testing

@testable import TodoMate

// MARK: - In-Memory Todo Repository

final class InMemoryTodoRepository: TodoRepository {
  var todos: [Todo] = []

  func create(_ todo: Todo) throws {
    todos.append(todo)
  }

  func update(_ todo: Todo) throws {
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
        case let .owner(userId):
          if todo.owner != userId { return false }
        case let .owners(userIds):
          if !userIds.contains(todo.owner) { return false }
        case let .dateRange(range):
          if !range.contains(todo.date) { return false }
        case let .status(status):
          if todo.status != status { return false }
        }
      }
      return true
    }
  }
}

// MARK: - CreateTodoUseCase Tests

@Suite("CreateTodoUseCase Unit Tests")
struct CreateTodoUseCaseTests {
  let repository = InMemoryTodoRepository()

  @Test("새 Todo 생성 및 저장")
  func createTodo_savesNewTodo() throws {
    // Given
    let useCase = CreateTodoUseCaseImpl(repository: repository)
    let userId = "user1"
    let todo = Todo(owner: userId, content: "Test Content")

    // When
    try useCase.run(for: userId, todo)

    // Then
    #expect(repository.todos.count == 1)
    #expect(repository.todos.first?.content == "Test Content")
    #expect(repository.todos.first?.owner == userId)
  }

  @Test("다른 사용자의 Todo 생성 시도 시 에러")
  func createTodo_throwsForUnauthorizedUser() {
    // Given
    let useCase = CreateTodoUseCaseImpl(repository: repository)
    let ownerId = "user1"
    let differentUserId = "user2"
    let todo = Todo(owner: ownerId, content: "Test")

    // When/Then
    #expect(throws: TodoUseCaseError.userNotAuthorized) {
      try useCase.run(for: differentUserId, todo)
    }
  }
}

// MARK: - UpdateTodoUseCase Tests

@Suite("UpdateTodoUseCase Unit Tests")
struct UpdateTodoUseCaseTests {
  @Test("기존 Todo 업데이트")
  func updateTodo_updatesExistingTodo() throws {
    // Given
    let repository = InMemoryTodoRepository()
    let useCase = UpdateTodoUseCaseImpl(repository: repository)

    let userId = "user1"
    var todo = Todo(owner: userId, content: "Original Content")
    repository.todos = [todo]

    // When
    todo.content = "Updated Content"
    todo.status = .complete
    try useCase.run(for: userId, todo)

    // Then
    #expect(repository.todos.first?.content == "Updated Content")
    #expect(repository.todos.first?.status == .complete)
  }

  @Test("다른 사용자의 Todo 수정 시도 시 에러")
  func updateTodo_throwsForUnauthorizedUser() {
    // Given
    let repository = InMemoryTodoRepository()
    let useCase = UpdateTodoUseCaseImpl(repository: repository)

    let ownerId = "user1"
    let differentUserId = "user2"
    let todo = Todo(owner: ownerId, content: "Test")
    repository.todos = [todo]

    // When/Then
    #expect(throws: TodoUseCaseError.userNotAuthorized) {
      try useCase.run(for: differentUserId, todo)
    }
  }
}

// MARK: - DeleteTodoUseCase Tests

@Suite("DeleteTodoUseCase Unit Tests")
struct DeleteTodoUseCaseTests {
  @Test("Todo 삭제")
  func deleteTodo_removesTodo() async throws {
    // Given
    let repository = InMemoryTodoRepository()
    let useCase = DeleteTodoUseCaseImpl(repository: repository)

    let userId = "user1"
    let todo = Todo(owner: userId, content: "To be deleted")
    repository.todos = [todo]

    // When
    try await useCase.run(for: userId, todo)

    // Then
    #expect(repository.todos.isEmpty)
  }

  @Test("다른 사용자의 Todo 삭제 시도 시 에러")
  func deleteTodo_throwsForUnauthorizedUser() async {
    // Given
    let repository = InMemoryTodoRepository()
    let useCase = DeleteTodoUseCaseImpl(repository: repository)

    let ownerId = "user1"
    let differentUserId = "user2"
    let todo = Todo(owner: ownerId, content: "Test")
    repository.todos = [todo]

    // When/Then
    do {
      try await useCase.run(for: differentUserId, todo)
      Issue.record("Expected error to be thrown")
    } catch {
      #expect(error as? TodoUseCaseError == .userNotAuthorized)
    }
  }
}

// MARK: - ReadGroupTodoUseCase Tests

@Suite("ReadGroupTodoUseCase Unit Tests")
struct ReadGroupTodoUseCaseTests {
  @Test("그룹 멤버 Todo 조회")
  func readGroupTodo_returnsTodosGroupedByOwner() async throws {
    // Given
    let repository = InMemoryTodoRepository()
    let useCase = ReadGroupTodoUseCaseImpl(repository: repository)

    let user1 = "user1"
    let user2 = "user2"
    let today = Date()

    let todo1 = Todo(owner: user1, content: "User1 Todo 1", in: today)
    let todo2 = Todo(owner: user1, content: "User1 Todo 2", in: today)
    let todo3 = Todo(owner: user2, content: "User2 Todo", in: today)
    repository.todos = [todo1, todo2, todo3]

    // When
    let result = try await useCase.run(for: [user1, user2], in: today, useCache: true)

    // Then
    #expect(result[user1]?.count == 2)
    #expect(result[user2]?.count == 1)
  }

  @Test("Todo가 없는 유저도 빈 배열로 반환")
  func readGroupTodo_returnsEmptyArrayForUserWithNoTodos() async throws {
    // Given
    let repository = InMemoryTodoRepository()
    let useCase = ReadGroupTodoUseCaseImpl(repository: repository)

    let user1 = "user1"
    let userWithNoTodos = "user_empty"
    let today = Date()

    repository.todos = [Todo(owner: user1, content: "Content", in: today)]

    // When
    let result = try await useCase.run(
      for: [user1, userWithNoTodos], in: today, useCache: true,
    )

    // Then
    #expect(result[user1]?.count == 1)
    #expect(result[userWithNoTodos]?.isEmpty == true)
  }

  @Test("날짜 필터링 동작 확인")
  func readGroupTodo_filtersbyDate() async throws {
    // Given
    let repository = InMemoryTodoRepository()
    let useCase = ReadGroupTodoUseCaseImpl(repository: repository)

    let userId = "user1"
    let today = Date()
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

    let todoToday = Todo(owner: userId, content: "Today", in: today)
    let todoTomorrow = Todo(owner: userId, content: "Tomorrow", in: tomorrow)
    repository.todos = [todoToday, todoTomorrow]

    // When
    let result = try await useCase.run(for: [userId], in: today, useCache: true)

    // Then
    #expect(result[userId]?.count == 1)
    #expect(result[userId]?.first?.content == "Today")
  }
}
