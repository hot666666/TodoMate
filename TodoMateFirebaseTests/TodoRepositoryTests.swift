//
//  TodoRepositoryTests.swift
//  TodoMateTests
//
//  Created by hs on 2026/01/06.
//

import Foundation
import Testing

@testable import TodoMate

/// Firebase 에뮬레이터를 사용한 TodoRepository 테스트
/// .serialized: 병렬 실행 시 resetAllCollections()가 다른 테스트 데이터를 삭제할 수 있어 직렬 실행 필수
@Suite("Todo Repository Integration Tests", .serialized)
struct TodoRepositoryTests {
  let repository: TodoRepository
  let testUserId = "test-user"

  init() async throws {
    #if USE_FIREBASE_EMULATOR
      // 각 테스트 전에 모든 컬렉션 리셋
      try await FirestoreReference.shared.resetAllCollections()
    #endif
    repository = FirestoreTodoRepository()
  }

  // MARK: - Create & Read

  @Test("Todo 생성 및 단일 조회 확인")
  func createAndReadTodo() async throws {
    // Given
    let todo = Todo(owner: testUserId, content: "Repository 테스트")

    // When
    try repository.create(todo)

    // Then
    let query = TodoQuery().owner(userId: testUserId)
    let results = try await repository.readAll(query: query, source: .server)

    let found = results.first { $0.id == todo.id }
    #expect(found != nil)
    #expect(found?.content == "Repository 테스트")
    #expect(found?.owner == testUserId)
  }

  // MARK: - Update

  @Test("Todo 내용 및 상태 수정")
  func updateTodo() async throws {
    // Given
    var todo = Todo(owner: testUserId, content: "수정 전")
    try repository.create(todo)

    // When
    todo.content = "수정 후"
    todo.status = .complete
    try repository.update(todo)

    // Then
    let query = TodoQuery().owner(userId: testUserId)
    let results = try await repository.readAll(query: query, source: .server)
    let updated = results.first { $0.id == todo.id }

    #expect(updated?.content == "수정 후")
    #expect(updated?.status == .complete)
  }

  // MARK: - Delete

  @Test("Todo 삭제")
  func deleteTodo() async throws {
    // Given
    let todo = Todo(owner: testUserId, content: "삭제될 할일")
    try repository.create(todo)

    // When
    try await repository.delete(todo.id)

    // Then
    let query = TodoQuery().owner(userId: testUserId)
    let results = try await repository.readAll(query: query, source: .server)
    #expect(!results.contains { $0.id == todo.id })
  }

  // MARK: - Query Filters

  @Test("다중 소유자(owners) 필터 테스트")
  func queryByOwners() async throws {
    // Given
    let otherUserId = "other-user"
    let todo1 = Todo(owner: testUserId, content: "내 할일")
    let todo2 = Todo(owner: otherUserId, content: "다른 사람 할일")
    let todo3 = Todo(owner: "random-user", content: "무관한 할일")

    try repository.create(todo1)
    try repository.create(todo2)
    try repository.create(todo3)

    // When
    let query = TodoQuery().owners(userIds: [testUserId, otherUserId])
    let results = try await repository.readAll(query: query, source: .server)

    // Then
    let ids = Set(results.map(\.id))
    #expect(ids.contains(todo1.id))
    #expect(ids.contains(todo2.id))
    #expect(!ids.contains(todo3.id))
  }

  @Test("날짜 범위(dateRange) 필터 테스트")
  func queryByDateRange() async throws {
    // Given
    let calendar = Calendar.current
    let today = Date()
    let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

    let todoToday = Todo(owner: testUserId, content: "오늘", in: today)
    let todoTomorrow = Todo(owner: testUserId, content: "내일", in: tomorrow)

    try repository.create(todoToday)
    try repository.create(todoTomorrow)

    // When: 오늘만 조회
    let range = today.startOfDay ... today.endOfDay
    let query = TodoQuery().owner(userId: testUserId).dateRange(range)
    let results = try await repository.readAll(query: query, source: .server)

    // Then
    #expect(results.count == 1)
    #expect(results.first?.id == todoToday.id)
  }

  @Test("상태(status) 필터 테스트")
  func queryByStatus() async throws {
    // Given
    var todo1 = Todo(owner: testUserId, content: "완료됨")
    todo1.status = .complete
    var todo2 = Todo(owner: testUserId, content: "진행중")
    todo2.status = .inProgress

    try repository.create(todo1)
    try repository.create(todo2)

    // When
    let query = TodoQuery().owner(userId: testUserId).status(.complete)
    let results = try await repository.readAll(query: query, source: .server)

    // Then
    #expect(results.count == 1)
    #expect(results.first?.id == todo1.id)
    #expect(results.first?.status == .complete)
  }
}
