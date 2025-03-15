////
////  TodoBoardViewModelTests.swift
////  TodoMate
////
////  Created by hs on 3/5/25.
////

import Foundation
import Testing
@testable import TodoMate

private enum TestFixtures {
  static let userInfo = AuthenticatedUser(uid: "user1", gid: "group1")
  static let todo1 = Todo(uid: "user1", fid: "todo1")
  static let todo2 = Todo(uid: "user1", fid: "todo2")
  static let todo3 = Todo(uid: "user1", fid: "todo3")
  static let otherUserTodo = Todo(uid: "user2", fid: "todo4")
  static let allTodos = ["user1": [todo1, todo2], "user2": [otherUserTodo]]
}

struct DummyTodoStreamProvider: TodoStreamProviderType {
  func createTodoStream() -> AsyncStream<DatabaseChange<Todo>> {
    AsyncStream { continuation in
      continuation.finish()
    }
  }
}

struct DummyTodoService: TodoServiceType {
  func fetchTodos() async throws -> [Todo] { [] }

  func create(from todo: Todo) async -> Todo? { nil }
  func fetchMonth(userId: String, startDate: Date, endDate: Date) async -> [Date: [Todo]] { [:] }
  func fetchToday(groupId: String) async -> [Todo] { [] }
  func update(_ todo: Todo) {}
  func remove(_ todo: Todo) {}
}

struct DummyTodoOrderService: TodoOrderServiceType {
  func loadOrder(for date: Date) -> [String]? { nil }
  func saveOrder(_ order: [String], for date: Date) {}
}

@Suite("TodoBoardViewModel Tests")
struct TodoBoardViewModelTests {
  static let container = DIContainer(
    testTodoService: DummyTodoService(),
    testTodoStreamProvider: DummyTodoStreamProvider(),
    testTodoOrderService: DummyTodoOrderService()
  )
  static let userInfo = TestFixtures.userInfo

  @Suite("상태 관리 메서드 테스트")
  struct StateManagementTests {
    @Test("setAllTodoStates가 todosByUser를 올바르게 업데이트")
    func testSetAllTodoStates() {
      // Given
      let viewModel = TodoBoardViewModel(container: container, userInfo: userInfo)

      // When
      viewModel.setAllTodoStates(with: TestFixtures.allTodos)

      // Then
      #expect(viewModel.todosByUser == TestFixtures.allTodos, "todosByUser가 입력된 전체 todos로 설정되어야 함")
    }

    @Test("setUserTodoStates가 현재 유저의 todos를 올바르게 업데이트")
    func testSetUserTodoStates() {
      // Given
      let viewModel = TodoBoardViewModel(container: container, userInfo: userInfo)
      let userTodos = [TestFixtures.todo1, TestFixtures.todo2]

      // When
      viewModel.setUserTodoStates(with: userTodos)

      // Then
      #expect(viewModel.todosByUser[userInfo.uid] == userTodos, "현재 유저의 todos가 올바르게 설정되어야 함")
      #expect(viewModel.todosByUser.count == 1, "다른 유저의 데이터는 추가되지 않아야 함")
    }

    @Test("addTodoState가 새로운 todo를 추가")
    func testAddTodoState() {
      // Given
      let viewModel = TodoBoardViewModel(container: container, userInfo: userInfo)
      viewModel.setUserTodoStates(with: [TestFixtures.todo1])

      // When
      viewModel.addTodoState(with: TestFixtures.todo2)

      // Then
      #expect(viewModel.todosByUser[userInfo.uid]?.count == 2, "todo가 추가되어야 함")
      #expect(
        viewModel.todosByUser[userInfo.uid]?.contains { $0.fid == "todo2" } == true,
        "추가된 todo가 포함되어야 함"
      )
    }

    @Test("updateTodoState가 기존 todo를 업데이트")
    func testUpdateTodoState() {
      // Given
      let viewModel = TodoBoardViewModel(container: container, userInfo: userInfo)
      viewModel.setUserTodoStates(with: [TestFixtures.todo1])
      let updatedTodo = Todo(uid: "user1", fid: "todo1") // 다른 속성이 변경되었다고 가정

      // When
      viewModel.updateTodoState(with: updatedTodo)

      // Then
      #expect(viewModel.todosByUser[userInfo.uid]?.first == updatedTodo, "todo가 업데이트되어야 함")
    }

    @Test("removeTodoState가 todo를 제거")
    func testRemoveTodoState() {
      // Given
      let viewModel = TodoBoardViewModel(container: container, userInfo: userInfo)
      viewModel.setUserTodoStates(with: [TestFixtures.todo1, TestFixtures.todo2])

      // When
      viewModel.removeTodoState(for: TestFixtures.todo1)

      // Then
      #expect(viewModel.todosByUser[userInfo.uid]?.count == 1, "todo가 제거되어야 함")
      #expect(
        viewModel.todosByUser[userInfo.uid]?.contains { $0.fid == "todo1" } == false,
        "제거된 todo가 없어야 함"
      )
    }
  }

  @Suite("handleTodoChange 메서드 테스트")
  struct HandleTodoChangeTests {
    @Test("handleTodoChange가 추가된 todo를 처리")
    func testHandleTodoChangeAdded() async {
      // Given
      let viewModel = TodoBoardViewModel(container: container, userInfo: userInfo)

      // When
      await viewModel.handleTodoChange(.added(TestFixtures.todo1))

      // Then
      #expect(
        viewModel.todosByUser[userInfo.uid]?.contains { $0.fid == "todo1" } == true,
        "새로운 todo가 추가되어야 함"
      )
    }

    @Test("handleTodoChange가 수정된 todo를 처리")
    func testHandleTodoChangeModified() async {
      // Given
      let viewModel = TodoBoardViewModel(container: container, userInfo: userInfo)
      viewModel.setUserTodoStates(with: [TestFixtures.todo1])
      let updatedTodo = Todo(uid: "user1", fid: "todo1") // 다른 속성이 변경되었다고 가정

      // When
      await viewModel.handleTodoChange(.modified(updatedTodo))

      // Then
      #expect(viewModel.todosByUser[userInfo.uid]?.first == updatedTodo, "todo가 수정되어야 함")
    }

    @Test("handleTodoChange가 제거된 todo를 처리")
    func testHandleTodoChangeRemoved() async {
      // Given
      let viewModel = TodoBoardViewModel(container: container, userInfo: userInfo)
      viewModel.setUserTodoStates(with: [TestFixtures.todo1])

      // When
      await viewModel.handleTodoChange(.removed(TestFixtures.todo1))

      // Then
      #expect(viewModel.todosByUser[userInfo.uid]?.isEmpty == true, "todo가 제거되어야 함")
    }
  }

  @Suite("moveTodo 메서드 테스트")
  struct MoveTodoTests {
    @Test("moveTodo가 todos를 재정렬하고 저장")
    func testMoveTodo() {
      // Given
      let viewModel = TodoBoardViewModel(container: container, userInfo: userInfo)
      viewModel.setUserTodoStates(with: [
        TestFixtures.todo1,
        TestFixtures.todo2,
        TestFixtures.todo3,
      ])

      // When
      let source = IndexSet(integer: 1) // todo2를 이동
      viewModel.moveTodo(from: source, to: 3) // 맨 끝으로 이동

      // Then
      let expectedTodos = [TestFixtures.todo1, TestFixtures.todo3, TestFixtures.todo2]
      #expect(viewModel.todosByUser[userInfo.uid] == expectedTodos, "todos가 재정렬되어야 함")
    }
  }

  @Suite("fetchTodos 메서드 테스트")
  struct FetchTodosTests {
    @Test("fetchTodos가 성공 시 todosByUser를 업데이트")
    func testFetchTodosSuccess() async {
      // Given
      let mockFetchUseCase = MockFetchTodosByUserUseCase()
      mockFetchUseCase.result = TestFixtures.allTodos
      let container = DIContainer(
        testTodoService: DummyTodoService(),
        testTodoStreamProvider: DummyTodoStreamProvider(),
        testTodoOrderService: DummyTodoOrderService(),
        testFetchTodosByUserUseCase: mockFetchUseCase
      )
      let viewModel = TodoBoardViewModel(container: container, userInfo: TestFixtures.userInfo)

      // When
      await viewModel.fetchTodos()

      // Then
      #expect(
        viewModel.todosByUser == TestFixtures.allTodos,
        "fetchTodos 성공 시 todosByUser가 업데이트되어야 함"
      )
    }

    @Test("fetchTodos가 실패 시 todosByUser를 변경하지 않음")
    func testFetchTodosFailure() async {
      // Given
      let mockFetchUseCase = MockFetchTodosByUserUseCase()
      mockFetchUseCase.shouldThrowError = true
      let container = DIContainer(
        testTodoService: DummyTodoService(),
        testTodoStreamProvider: DummyTodoStreamProvider(),
        testTodoOrderService: DummyTodoOrderService(),
        testFetchTodosByUserUseCase: mockFetchUseCase
      )
      let viewModel = TodoBoardViewModel(container: container, userInfo: TestFixtures.userInfo)
      let initialTodos = ["user1": [TestFixtures.todo1]]
      viewModel.setAllTodoStates(with: initialTodos)

      // When
      await viewModel.fetchTodos()

      // Then
      #expect(viewModel.todosByUser == initialTodos, "fetchTodos 실패 시 todosByUser가 변경되지 않아야 함")
    }
  }
}
