//
//  TodoOwnershipTests.swift
//  TodoMateTests
//
//  Created by agent on 12/28/25.
//

import Testing

@testable import TodoMate

/// Todo 소유권 검증 비즈니스 로직 테스트
struct TodoOwnershipTests {
  @Test func ownerCanAccessTodo() {
    let todo = Todo(groupId: nil, owner: "user-123", content: "할 일")

    #expect(todo.isOwned(by: "user-123") == true)
  }

  @Test func nonOwnerCannotAccessTodo() {
    let todo = Todo(groupId: nil, owner: "user-123", content: "할 일")

    #expect(todo.isOwned(by: "other-user") == false)
  }

  @Test func nilUserIdCannotAccessTodo() {
    let todo = Todo(groupId: nil, owner: "user-123", content: "할 일")

    #expect(todo.isOwned(by: nil) == false)
  }

  @Test func emptyStringIsNotOwner() {
    let todo = Todo(groupId: nil, owner: "user-123", content: "할 일")

    #expect(todo.isOwned(by: "") == false)
  }

  @Test func ownerComparisonIsCaseSensitive() {
    let todo = Todo(groupId: nil, owner: "User-123", content: "할 일")

    #expect(todo.isOwned(by: "user-123") == false)
    #expect(todo.isOwned(by: "User-123") == true)
  }
}
