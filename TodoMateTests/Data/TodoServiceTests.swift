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

  // update 성공
  static func todoRepositoryForUpdateSuccess() -> MockTodoRepository {
    var repo = MockTodoRepository()
    repo.updateHandler = { _ in } // 성공적으로 완료 (아무것도 하지 않음)
    return repo
  }

  // update 실패
  static func todoRepositoryForUpdateFailure(error: Error = NSError(
    domain: "Test",
    code: -1,
    userInfo: [NSLocalizedDescriptionKey: "Mock Failure"]
  )) -> MockTodoRepository {
    var repo = MockTodoRepository()
    repo.updateHandler = { _ in throw error } // 오류 발생
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

  @Suite("update 메서드 테스트")
  struct UpdateTests {
    @Test("진행 중인 Todo의 날짜 변경 시 오류 발생")
    func updateFailsWhenChangingDateOfInProgressTodo() throws {
      // Given: 진행 중인 Todo와 날짜가 변경된 새 Todo 준비
      let todoService = TodoService(todoRepository: TestFixtures.todoRepositoryForUpdateSuccess())
      let inProgressTodo = Todo(
        date: Date(),
        content: "test",
        detail: "test-detail",
        status: .inProgress,
        uid: "test-uid",
        fid: "test-fid",
        lastModifiedAt: Date()
      )
      let newDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
      let newTodo = Todo(
        date: newDate,
        content: "test",
        detail: "test-detail",
        status: .inProgress,
        uid: "test-uid",
        fid: "test-fid",
        lastModifiedAt: Date()
      )

      // When & Then: 업데이트 시 invalidUpdate 오류 발생 확인
      #expect(throws: TodoServiceError.invalidUpdate) {
        try todoService.update(from: inProgressTodo, with: newTodo)
      }
    }

    @Test("진행 중인 Todo의 날짜 변경 없이 업데이트 성공")
    func updateSucceedsWhenNotChangingDateOfInProgressTodo() throws {
      // Given: 진행 중인 Todo와 날짜가 동일한 새 Todo 준비
      let todoService = TodoService(todoRepository: TestFixtures.todoRepositoryForUpdateSuccess())
      let inProgressTodo = Todo(
        date: Date(),
        content: "test",
        detail: "test-detail",
        status: .inProgress,
        uid: "test-uid",
        fid: "test-fid",
        lastModifiedAt: Date()
      )
      let newTodo = Todo(
        date: inProgressTodo.date, // 날짜 동일
        content: "updated",
        detail: "updated-detail",
        status: .inProgress,
        uid: "test-uid",
        fid: "test-fid",
        lastModifiedAt: Date()
      )

      // When & Then: 업데이트 시 오류가 발생하지 않음 확인
      #expect(throws: Never.self) {
        try todoService.update(from: inProgressTodo, with: newTodo)
      }
    }

    @Test("진행 중이 아닌 Todo의 날짜 변경 성공")
    func updateSucceedsWhenChangingDateOfNotInProgressTodo() throws {
      // Given: 진행 중이 아닌 Todo와 날짜가 변경된 새 Todo 준비
      let todoService = TodoService(todoRepository: TestFixtures.todoRepositoryForUpdateSuccess())
      let notInProgressTodo = Todo(
        date: Date(),
        content: "test",
        detail: "test-detail",
        status: .todo, // 진행 중 아님
        uid: "test-uid",
        fid: "test-fid",
        lastModifiedAt: Date()
      )
      let newDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
      let newTodo = Todo(
        date: newDate,
        content: "test",
        detail: "test-detail",
        status: .todo,
        uid: "test-uid",
        fid: "test-fid",
        lastModifiedAt: Date()
      )

      // When & Then: 업데이트 시 오류가 발생하지 않음 확인
      #expect(throws: Never.self) {
        try todoService.update(from: notInProgressTodo, with: newTodo)
      }
    }

    @Test("업데이트 중 repository 오류 발생")
    func updateFailsWhenRepositoryThrowsError() throws {
      // Given: repository가 오류를 발생시키는 TodoService와 Todo 준비
      let todoService = TodoService(todoRepository: TestFixtures.todoRepositoryForUpdateFailure())
      let todo = TestFixtures.mockTodo
      let newTodo = Todo(
        date: todo.date,
        content: "updated",
        detail: "updated-detail",
        status: todo.status,
        uid: todo.uid,
        fid: todo.fid,
        lastModifiedAt: Date()
      )

      // When & Then: 업데이트 시 오류가 발생하는지 확인
      #expect(throws: Error.self) {
        try todoService.update(from: todo, with: newTodo)
      }
    }
  }
}
