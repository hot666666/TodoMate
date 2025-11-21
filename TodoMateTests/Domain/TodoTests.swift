//
//  TodoTests.swift
//  TodoMateTests
//
//  Created by hs on 7/21/25.
//

import Testing
import Foundation

@testable import TodoMate

@Suite("Todo Entity Tests")
struct TodoTests {
  @Test("Todo는 새로운 내용으로 업데이트할 수 있다")
  func testWithUpdatedContent() {
    let todo = Todo(owner: "user1")
    let updatedTodo = todo.withUpdatedContent("New content")

    #expect(updatedTodo.content == "New content")
    #expect(updatedTodo.id == todo.id)
    #expect(updatedTodo.owner == todo.owner)
  }

  @Test("Todo는 상태를 변경할 수 있다")
  func testWithUpdatedStatus() {
    let todo = Todo(owner: "user1")
    let updatedTodo = todo.withUpdatedStatus(.inProgress)

    #expect(updatedTodo.status == .inProgress)
    #expect(updatedTodo.id == todo.id)
  }

  @Test("Todo는 날짜를 변경할 수 있다")
  func testWithUpdatedDate() {
    let todo = Todo(owner: "user1")
    let newDate = Date().addingTimeInterval(86400) // +1 day
    let updatedTodo = todo.withUpdatedDate(newDate)

    #expect(updatedTodo.date.timeIntervalSince1970 == newDate.timeIntervalSince1970)
    #expect(updatedTodo.id == todo.id)
  }

  @Test("Todo는 복사를 생성할 수 있다")
  func testCopy() {
    let original = Todo(owner: "user1", content: "Original", date: Date())
    let copy = original.copy()

    #expect(copy.id != original.id)
    #expect(copy.content == original.content)
    #expect(copy.owner == original.owner)
    #expect(copy.status == original.status)
  }

  @Test("TodoStatus는 올바른 표시 텍스트를 반환한다")
  func testTodoStatusDisplay() {
    #expect(TodoStatus.notStarted.displayText == "시작 전")
    #expect(TodoStatus.inProgress.displayText == "진행 중")
    #expect(TodoStatus.done.displayText == "완료")
    #expect(TodoStatus.incomplete.displayText == "미완료")
  }

  @Test("TodoStatus는 올바른 순서를 갖는다")
  func testTodoStatusOrder() {
    #expect(TodoStatus.notStarted.rawValue == 0)
    #expect(TodoStatus.inProgress.rawValue == 1)
    #expect(TodoStatus.done.rawValue == 2)
    #expect(TodoStatus.incomplete.rawValue == 3)
  }
}
