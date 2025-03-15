//
//  FetchUserGroupTodosWithOrderUseCaseTests.swift
//  TodoMate
//
//  Created by hs on 3/9/25.
//

import Foundation
import Testing
@testable import TodoMate

private enum TestFixtures {
  static let userInfo = AuthenticatedUser(uid: "user1", gid: "group1")
  static let today = Calendar.current.startOfDay(for: .now)
  static let todo1 = Todo(uid: "user1", fid: "todo1")
  static let todo2 = Todo(uid: "user1", fid: "todo2")
  static let todo3 = Todo(uid: "user2", fid: "todo3")
  static let userTodos = [todo1, todo2]
  static let groupTodos = [todo1, todo2, todo3]
  static let existingOrder = ["todo2", "todo1"] // todo2 -> todo1 순서
}

@Suite("FetchUserGroupTodosWithOrderUseCase Tests")
struct FetchUserGroupTodosWithOrderUseCaseTests {
  @Suite("execute 메서드 테스트")
  struct ExecuteTests {
    @Test("기존 순서가 있을 때 순서가 적용된 todos를 반환")
    func testExecuteWithExistingOrder() async throws {
      // Given
      let mockTodoService = MockTodoService()
      mockTodoService.fetchTodayResult = TestFixtures.groupTodos
      let mockTodoOrderService = MockTodoOrderService()
      mockTodoOrderService.loadOrderResult = TestFixtures.existingOrder
      let useCase = FetchUserGroupTodosWithOrderUseCase(
        todoService: mockTodoService,
        todoOrderService: mockTodoOrderService
      )

      // When
      let result = try await useCase.execute(for: TestFixtures.userInfo)

      // Then
      let expectedUserTodos = [TestFixtures.todo2, TestFixtures.todo1]
      #expect(result[TestFixtures.userInfo.uid] == expectedUserTodos, "기존 순서가 적용된 todos가 반환되어야 함")
      #expect(result["user2"] == [TestFixtures.todo3], "다른 사용자의 todos는 순서 없이 유지되어야 함")
      #expect(mockTodoOrderService.savedOrder == nil, "기존 순서가 있으면 새 순서를 저장하지 않아야 함")
    }

    @Test("기존 순서가 없을 때 새 순서를 생성하고 저장")
    func testExecuteWithNoExistingOrder() async throws {
      // Given
      let mockTodoService = MockTodoService()
      mockTodoService.fetchTodayResult = TestFixtures.groupTodos
      let mockTodoOrderService = MockTodoOrderService()
      mockTodoOrderService.loadOrderResult = nil
      let useCase = FetchUserGroupTodosWithOrderUseCase(
        todoService: mockTodoService,
        todoOrderService: mockTodoOrderService
      )

      // When
      let result = try await useCase.execute(for: TestFixtures.userInfo)

      // Then
      let expectedUserTodos = TestFixtures.userTodos // 기본 순서 (todo1, todo2)
      let expectedOrder = ["todo1", "todo2"]
      #expect(result[TestFixtures.userInfo.uid] == expectedUserTodos, "기본 순서의 todos가 반환되어야 함")
      #expect(mockTodoOrderService.savedOrder == expectedOrder, "새 순서가 생성되고 저장되어야 함")
      #expect(mockTodoOrderService.savedDate == TestFixtures.today, "오늘 날짜로 순서가 저장되어야 함")
    }

    @Test("사용자 todos가 없으면 오류를 던짐")
    func testExecuteThrowsWhenUserNotFound() async {
      // Given
      let mockTodoService = MockTodoService()
      mockTodoService.fetchTodayResult = [TestFixtures.todo3] // user1의 todo 없음
      let mockTodoOrderService = MockTodoOrderService()
      let useCase = FetchUserGroupTodosWithOrderUseCase(
        todoService: mockTodoService,
        todoOrderService: mockTodoOrderService
      )

      // When & Then
      await #expect(throws: FetchUserGrouptodosWithOrderUseCaseError.userNotFoundInTodos) {
        _ = try await useCase.execute(for: TestFixtures.userInfo)
      }
    }
  }
}
