//
//  TodoGroupFilterTests.swift
//  TodoMateTests
//
//  Created by agent on 12/28/25.
//

import Testing

@testable import TodoMate

/// Todo 그룹 필터링 비즈니스 로직 테스트
struct TodoGroupFilterTests {
  @Test func personalTodoHasNilGroupId() {
    let todo = Todo(groupId: nil, owner: "user-123", content: "개인 할 일")

    #expect(todo.groupId == nil)
  }

  @Test func groupTodoHasGroupId() {
    let todo = Todo(groupId: "group-456", owner: "user-123", content: "그룹 할 일")

    #expect(todo.groupId == "group-456")
  }

  @Test func groupIdIsImmutableAfterCreation() {
    // groupId는 let으로 선언되어 생성 후 변경 불가 - 컴파일 타임 보장
    let todo = Todo(groupId: "original-group", owner: "user", content: "할 일")

    #expect(todo.groupId == "original-group")
    // todo.groupId = "new-group" // 컴파일 에러 발생해야 함
  }

  @Test func filterPersonalTodosFromMixedList() {
    let todos = [
      Todo(groupId: nil, owner: "user-1", content: "개인1"),
      Todo(groupId: "group-a", owner: "user-1", content: "그룹1"),
      Todo(groupId: nil, owner: "user-1", content: "개인2"),
      Todo(groupId: "group-a", owner: "user-2", content: "그룹2"),
    ]

    let personalTodos = todos.filter { $0.groupId == nil }

    #expect(personalTodos.count == 2)
    #expect(personalTodos.allSatisfy { $0.groupId == nil })
  }

  @Test func filterGroupTodosById() {
    let todos = [
      Todo(groupId: "group-a", owner: "user-1", content: "그룹A-1"),
      Todo(groupId: "group-b", owner: "user-2", content: "그룹B-1"),
      Todo(groupId: "group-a", owner: "user-3", content: "그룹A-2"),
      Todo(groupId: nil, owner: "user-1", content: "개인"),
    ]

    let groupATodos = todos.filter { $0.groupId == "group-a" }

    #expect(groupATodos.count == 2)
    #expect(groupATodos.allSatisfy { $0.groupId == "group-a" })
  }
}
