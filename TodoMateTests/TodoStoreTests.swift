//
//  TodoStoreTests.swift
//  TodoMateTests
//
//  Created by agent on 1/6/26.
//

import Foundation
import Testing

@testable import TodoMate

@MainActor
struct TodoStoreTests {
  @Test("Load with wide range loads all matching todos")
  func loadWideRange() async throws {
    // Given
    let today = Date()
    let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: today)!
    let userId = "user1"

    let todoToday = Todo(owner: userId, content: "Today", in: today)
    let todoLastWeek = Todo(owner: userId, content: "Last Week", in: lastWeek)

    let mockRepo = MockTodoRepository(todos: [todoToday, todoLastWeek])
    let container = createMockContainer(repo: mockRepo, userId: userId)
    let store = TodoStore(container: container)

    // When
    await store.load(for: [userId], range: today.monthRange, useCache: true)

    // Then
    let todos = store.todos[userId] ?? []
    #expect(todos.count == 2)
    #expect(todos.contains(where: { $0.id == todoToday.id }))
    #expect(todos.contains(where: { $0.id == todoLastWeek.id }))
  }

  @Test("Load with narrow range updates only relevant todos and preserves others")
  func loadNarrowRangeMerges() async throws {
    // Given
    let today = Date()
    let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: today)!
    let userId = "user1"

    let todoToday = Todo(owner: userId, content: "Today Original", in: today)
    let todoLastWeek = Todo(owner: userId, content: "Last Week", in: lastWeek)

    let mockRepo = MockTodoRepository(todos: [todoToday, todoLastWeek])
    let container = createMockContainer(repo: mockRepo, userId: userId)
    let store = TodoStore(container: container)

    // Initial Load (Wide Range)
    await store.load(for: [userId], range: today.monthRange, useCache: true)
    #expect(store.todos[userId]?.count == 2)

    // Update Repository (Server Update)
    let todoTodayUpdated = todoToday.withUpdatedStatus(.complete)
    try mockRepo.update(todoTodayUpdated)

    // When: Load Narrow Range (Today)
    await store.load(for: [userId], range: today.dayRange, useCache: false)

    // Then
    let todos = store.todos[userId] ?? []
    #expect(todos.count == 2) // Should still have 2 todos

    // Verify Last Week Todo is Preserved
    #expect(todos.contains(where: { $0.id == todoLastWeek.id }))

    // Verify Today Todo is Updated
    let fetchedTodoToday = todos.first(where: { $0.id == todoToday.id })
    #expect(fetchedTodoToday?.status == .complete)
  }

  // MARK: - Helpers

  private func createMockContainer(repo: MockTodoRepository, userId: String) -> PublicDIContainer {
    let user = User(id: userId, displayName: "Test User", groupId: "")
    return PublicDIContainer(
      userRepository: MockUserRepository(currentUser: user, groupMembers: []),
      todoRepository: repo,
      messageRepository: MockMessageRepository(messages: []),
      groupRepository: StubGroupRepository(),
      authService: MockAuthService(userId: userId),
      messageReadTracker: StubMessageReadTracker(),
    )
  }
}
