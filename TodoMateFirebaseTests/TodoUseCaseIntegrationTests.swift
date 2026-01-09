//
//  TodoUseCaseIntegrationTests.swift
//  TodoMateTests
//
//  Created by hs on 2026/01/06.
//

import Foundation
import Testing

@testable import TodoMate

extension FirebaseIntegrationTests {
  /// Firebase 에뮬레이터를 사용한 Todo UseCase 테스트
  @Suite("Todo UseCase Integration Tests", .serialized)
  struct TodoUseCaseIntegrationTests {
    let repository: TodoRepository
    let createUseCase: CreateTodoUseCase
    let readUseCase: ReadMonthlyTodoUseCase
    let deleteUseCase: DeleteTodoUseCase

    let testUserId = "test-user"

    init() async throws {
      try await FirebaseIntegrationTests.setup()
      repository = FirestoreTodoRepository()
      createUseCase = CreateTodoUseCaseImpl(repository: repository)
      readUseCase = ReadMonthlyTodoUseCaseImpl(repository: repository)
      deleteUseCase = DeleteTodoUseCaseImpl(repository: repository)
    }

    // MARK: - Create

    @Test("Todo 생성 후 조회 가능")
    func createTodo() async throws {
      // Given
      let todo = Todo(owner: testUserId, content: "테스트 할일", detail: "상세 내용")
      let dateRange = todo.date.startOfDay ... todo.date.endOfDay

      // When
      try createUseCase.run(for: testUserId, todo)

      // Then
      let todos = try await readUseCase.run(for: testUserId, range: dateRange, useCache: false)
      let found = todos.first { $0.id == todo.id }
      #expect(found != nil)
      #expect(found?.content == "테스트 할일")
      #expect(found?.detail == "상세 내용")
    }

    // MARK: - Read

    @Test("특정 날짜 범위의 Todo 조회")
    func readTodosInDateRange() async throws {
      // Given
      let today = Date()
      let todo1 = Todo(owner: testUserId, content: "오늘 할일 1", in: today)
      let todo2 = Todo(owner: testUserId, content: "오늘 할일 2", in: today)

      try createUseCase.run(for: testUserId, todo1)
      try createUseCase.run(for: testUserId, todo2)

      // When
      let dateRange = today.startOfDay ... today.endOfDay
      let todos = try await readUseCase.run(for: testUserId, range: dateRange, useCache: false)

      // Then
      let foundIds = Set(todos.map(\.id))
      #expect(foundIds.contains(todo1.id))
      #expect(foundIds.contains(todo2.id))
    }

    @Test("다른 사용자의 Todo는 조회되지 않음")
    func readOnlyOwnTodos() async throws {
      // Given
      let otherUserId = "other-user"
      let myTodo = Todo(owner: testUserId, content: "내 할일")
      let otherTodo = Todo(owner: otherUserId, content: "다른 사람 할일")

      try createUseCase.run(for: testUserId, myTodo)
      try createUseCase.run(for: otherUserId, otherTodo)

      // When
      let dateRange = myTodo.date ... myTodo.date
      let myTodos = try await readUseCase.run(for: testUserId, range: dateRange, useCache: false)

      // Then
      let ids = Set(myTodos.map(\.id))
      #expect(ids.contains(myTodo.id))
      #expect(!ids.contains(otherTodo.id))
    }

    // MARK: - Delete

    @Test("Todo 삭제 후 조회되지 않음")
    func deleteTodo() async throws {
      // Given
      let todo = Todo(owner: testUserId, content: "삭제할 할일")
      try createUseCase.run(for: testUserId, todo)

      let dateRange = todo.date ... todo.date
      let beforeDelete = try await readUseCase.run(
        for: testUserId, range: dateRange, useCache: false,
      )
      #expect(beforeDelete.contains { $0.id == todo.id })

      // When
      try await deleteUseCase.run(for: testUserId, todo)

      // Then
      let afterDelete = try await readUseCase.run(
        for: testUserId, range: dateRange, useCache: false,
      )
      #expect(!afterDelete.contains { $0.id == todo.id })
    }

    @Test("다른 사용자의 Todo 삭제 시도하면 에러 발생")
    func deleteOtherUserTodoFails() async throws {
      // Given
      let otherUserId = "other-user"
      let otherTodo = Todo(owner: otherUserId, content: "다른 사람 할일")
      try createUseCase.run(for: otherUserId, otherTodo)

      // When & Then
      await #expect(throws: TodoUseCaseError.userNotAuthorized) {
        try await deleteUseCase.run(for: testUserId, otherTodo)
      }
    }
  }
}
