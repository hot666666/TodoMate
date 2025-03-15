//
//  TodoServiceTests.swift
//  TodoMate
//
//  Created by hs on 3/7/25.
//

import Foundation
import Testing
@testable import TodoMate

private enum TestFixtures {
  private static let now = Date()
  static let mockTodo = Todo(
    date: now,
    content: "test",
    detail: "test-detail",
    status: .todo,
    uid: "test-uid",
    fid: "test-fid",
    lastModifiedAt: now
  )
  static let mockTodoDTO = mockTodo.toDTO()
  static let mockTodos = [mockTodo]
  static let mockTodoDTOs = [mockTodoDTO]

  // create 성공
  static func todoRepositoryForCreateSuccess(returnValue: TodoDTO = mockTodoDTO)
    -> MockTodoRepository {
    var repo = MockTodoRepository()
    repo.createTodoHandler = { _ in returnValue }
    return repo
  }

  // create 실패
  static func todoRepositoryForCreateFailure(error: Error = NSError(
    domain: "Test",
    code: -1,
    userInfo: [NSLocalizedDescriptionKey: "Mock Failure"]
  )) -> MockTodoRepository {
    var repo = MockTodoRepository()
    repo.createTodoHandler = { _ in throw error }
    return repo
  }

  // fetchMonth 성공
  static func todoRepositoryForFetchUserMonthSuccess(returnValue: [TodoDTO] = mockTodoDTOs)
    -> MockTodoRepository {
    var repo = MockTodoRepository()
    repo.fetchTodosByUserHandler = { _, _, _ in returnValue }
    return repo
  }

  // fetchMonth 실패
  static func todoRepositoryForFetchUserMonthFailure(error: Error = NSError(
    domain: "Test",
    code: -1,
    userInfo: [NSLocalizedDescriptionKey: "Mock Failure"]
  )) -> MockTodoRepository {
    var repo = MockTodoRepository()
    repo.fetchTodosByUserHandler = { _, _, _ in throw error }
    return repo
  }

  // fetch(groupId:) 성공
  static func todoRepositoryForFetchGroupSuccess(returnValue: [TodoDTO] = mockTodoDTOs)
    -> MockTodoRepository {
    var repo = MockTodoRepository()
    repo.fetchTodosByGroupHandler = { _, _, _ in returnValue }
    return repo
  }

  // fetch(groupId:) 실패
  static func todoRepositoryForFetchGroupFailure(error: Error = NSError(
    domain: "Test",
    code: -1,
    userInfo: [NSLocalizedDescriptionKey: "Mock Failure"]
  )) -> MockTodoRepository {
    var repo = MockTodoRepository()
    repo.fetchTodosByGroupHandler = { _, _, _ in throw error }
    return repo
  }
}

@Suite("TodoService Tests")
struct TodoServiceTests {
  @Suite("create 메서드 테스트")
  struct CreateTests {
    @Test("create 성공")
    func createSucceeds() async {
      // Given
      let todoService = TodoService(todoRepository: TestFixtures.todoRepositoryForCreateSuccess())

      // When
      let result = await todoService.create(from: TestFixtures.mockTodo)

      // Then
      #expect(result != nil, "create 성공 시 Todo가 반환되어야 함")
      #expect(result?.fid == TestFixtures.mockTodo.fid, "반환된 Todo의 fid는 mockTodo의 fid와 같아야 함")
    }

    @Test("create 실패")
    func createFails() async {
      // Given
      let todoService = TodoService(todoRepository: TestFixtures.todoRepositoryForCreateFailure())

      // When
      let result = await todoService.create(from: TestFixtures.mockTodo)

      // Then
      #expect(result == nil, "create 실패 시 nil이 반환되어야 함")
    }
  }

  @Suite("fetchMonth 메서드 테스트")
  struct FetchMonthTests {
    @Test("fetchMonth 성공")
    func fetchMonthSucceeds() async {
      // Given
      let todoService = TodoService(todoRepository: TestFixtures
        .todoRepositoryForFetchUserMonthSuccess())
      let startDate = Date()
      let endDate = Date()

      // When
      let result = await todoService.fetchMonth(
        userId: "test-uid",
        startDate: startDate,
        endDate: endDate
      )

      // Then
      #expect(!result.isEmpty, "fetchMonth 성공 시 비어 있지 않은 딕셔너리가 반환되어야 함")
      let todosForDate = result[Calendar.current.startOfDay(for: TestFixtures.mockTodo.date)]
      #expect(todosForDate?.count == 1, "fetch된 Todo는 1개여야 함")
    }

    @Test("fetchMonth 실패")
    func fetchMonthFails() async {
      // Given
      let todoService = TodoService(todoRepository: TestFixtures
        .todoRepositoryForFetchUserMonthFailure())
      let startDate = Date()
      let endDate = Date()

      // When
      let result = await todoService.fetchMonth(
        userId: "test-uid",
        startDate: startDate,
        endDate: endDate
      )

      // Then
      #expect(result.isEmpty, "fetchMonth 실패 시 빈 딕셔너리가 반환되어야 함")
    }
  }

  @Suite("fetchToday(groupId:) 메서드 테스트")
  struct FetchTodayGroupTests {
    @Test("fetchToday 성공")
    func fetchTodaySucceeds() async {
      // Given
      let todoService = TodoService(todoRepository: TestFixtures
        .todoRepositoryForFetchGroupSuccess())

      // When
      let result = await todoService.fetchToday(groupId: "test-gid")

      // Then
      #expect(result.count == 1, "fetchToday 성공 시 1개의 Todo가 반환되어야 함")
      #expect(result.first?.fid == TestFixtures.mockTodo.fid, "반환된 Todo의 fid는 mockTodo의 fid와 같아야 함")
    }

    @Test("fetchToday 실패")
    func fetchTodayFails() async {
      // Given
      let todoService = TodoService(todoRepository: TestFixtures
        .todoRepositoryForFetchGroupFailure())

      // When
      let result = await todoService.fetchToday(groupId: "test-gid")

      // Then
      #expect(result.isEmpty, "fetchToday 실패 시 빈 배열이 반환되어야 함")
    }
  }
}
