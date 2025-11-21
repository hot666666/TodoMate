//
//  TodoStoreTests.swift
//  TodoMateTests
//
//  Created by hs on 7/21/25.
//

import Testing
import Foundation

@testable import TodoMate

@Suite("TodoStore Tests")
struct TodoStoreTests {
  // MARK: - Mock Setup

  private func createMockContainer(todoRepository: TodoRepository) -> DIContainer {
    DIContainer(
      todoRepository: todoRepository,
      userRepository: DIContainer.preview.userRepository,
      messageRepository: DIContainer.preview.messageRepository,
      memoRepository: DIContainer.preview.memoRepository,
      todoOrderRepository: DIContainer.preview.todoOrderRepository,
      authService: DIContainer.preview.authService,
      widgetSyncService: DIContainer.preview.widgetSyncService,
      messageReadTracker: DIContainer.preview.messageReadTracker
    )
  }

  // MARK: - Tests

  @Test("TodoStore는 초기 상태를 올바르게 설정한다")
  func testInitialState() {
    let mockRepo = MockTodoRepository()
    let container = createMockContainer(todoRepository: mockRepo)
    let store = TodoStore(container: container)

    #expect(store.todos.isEmpty)
    #expect(!store.isLoading)
    #expect(store.error == nil)
  }

  @Test("TodoStore는 할일을 추가할 수 있다")
  func testAddTodo() async throws {
    let mockRepo = MockTodoRepository()
    let container = createMockContainer(todoRepository: mockRepo)
    let store = TodoStore(container: container)

    let userId = "user1"
    let todo = Todo(owner: userId)

    store.add(todo, userId: userId)

    // Optimistic update로 즉시 추가됨
    #expect(store.todos[userId]?.contains(where: { $0.id == todo.id }) == true)
  }

  @Test("TodoStore는 할일 추가 실패 시 에러를 설정한다")
  func testAddTodoFailure() async throws {
    let mockRepo = MockTodoRepository()
    mockRepo.shouldThrowError = true
    let container = createMockContainer(todoRepository: mockRepo)
    let store = TodoStore(container: container)

    let userId = "user1"
    let todo = Todo(owner: userId)

    store.add(todo, userId: userId)

    #expect(store.error != nil)
  }

  @Test("TodoStore는 할일을 업데이트할 수 있다")
  func testUpdateTodo() async throws {
    let mockRepo = MockTodoRepository()
    let container = createMockContainer(todoRepository: mockRepo)
    let store = TodoStore(container: container)

    let userId = "user1"
    let todo = Todo(owner: userId)
    store.add(todo, userId: userId)

    let updatedTodo = todo.withUpdatedContent("Updated content")
    store.update(updatedTodo, userId: userId)

    #expect(store.todos[userId]?.first?.content == "Updated content")
  }

  @Test("TodoStore는 할일을 삭제할 수 있다")
  func testDeleteTodo() async throws {
    let mockRepo = MockTodoRepository()
    let container = createMockContainer(todoRepository: mockRepo)
    let store = TodoStore(container: container)

    let userId = "user1"
    let todo = Todo(owner: userId)
    store.add(todo, userId: userId)

    #expect(store.todos[userId]?.count == 1)

    store.delete(todo, userId: userId)

    // 비동기 삭제이므로 잠시 대기
    try await Task.sleep(for: .milliseconds(100))

    #expect(store.todos[userId]?.isEmpty == true)
  }

  @Test("TodoStore는 여러 사용자의 할일을 로드할 수 있다")
  func testLoadGroupTodos() async throws {
    let mockRepo = MockTodoRepository()
    let user1 = "user1"
    let user2 = "user2"
    mockRepo.todos = [
      user1: [Todo(owner: user1)],
      user2: [Todo(owner: user2), Todo(owner: user2)],
    ]

    let container = createMockContainer(todoRepository: mockRepo)
    let store = TodoStore(container: container)

    await store.load(for: [user1, user2], currentUserId: user1)

    #expect(store.todos[user1]?.count == 1)
    #expect(store.todos[user2]?.count == 2)
    #expect(!store.isLoading)
  }

  @Test("TodoStore는 로딩 실패 시 에러를 설정한다")
  func testLoadFailure() async throws {
    let mockRepo = MockTodoRepository()
    mockRepo.shouldThrowError = true
    let container = createMockContainer(todoRepository: mockRepo)
    let store = TodoStore(container: container)

    await store.load(for: ["user1"], currentUserId: "user1")

    #expect(store.error != nil)
    #expect(!store.isLoading)
    #expect(store.todos.isEmpty)
  }
}
