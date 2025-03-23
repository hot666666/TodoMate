//
//  RealTodoStreamProviderTests.swift
//  TodoMate
//
//  Created by hs on 3/23/25.
//

import Foundation
import Testing
@testable import TodoMate

private enum TestingError: Error {
  case failed(String)
}

// firebase emulators:start --only firestore --project [PROJECT_ID]
@Suite("Real TodoStreamProvider Tests")
struct TodoRealtimeTests {
  private let userId = "testUser"
  private let groupId = "testGroup"
  private let todoService: TodoService
  private let streamProvider: FirestoreTodoStreamProvider

  init() {
    todoService = TodoService()
    streamProvider = FirestoreTodoStreamProvider()
  }

  @Test("Todo 생성 시 스트림이 .added 이벤트를 방출하는지 확인")
  func testTodoAdded() async throws {
    // Given: 스트림 생성
    let stream = streamProvider.createTodoStream()

    // When: 새로운 Todo 생성
    let newTodo = Todo(
      date: Date(),
      content: "Test Todo",
      detail: "",
      status: .todo,
      uid: userId,
      fid: "",
      lastModifiedAt: Date()
    )
    guard let createdTodo = await todoService.create(from: newTodo) else {
      throw TestingError.failed("Todo creation failed")
    }

    // Then: 스트림에서 .added 이벤트 감지
    var eventReceived = false
    for await change in stream {
      if case let .added(todo) = change, todo.fid == createdTodo.fid {
        #expect(todo.content == "Test Todo", "생성된 Todo의 내용이 일치해야 합니다.")
        eventReceived = true
        break
      }
    }

    #expect(eventReceived == true, "Todo 추가 이벤트를 수신해야 합니다.")
  }

  @Test("Todo 수정 시 스트림이 .modified 이벤트를 방출하는지 확인")
  func testTodoModified() async throws {
    // Given: 기존 Todo 생성
    let initialTodo = Todo(
      date: Date(),
      content: "Initial Todo",
      detail: "",
      status: .todo,
      uid: userId,
      fid: "",
      lastModifiedAt: Date()
    )
    guard let createdTodo = await todoService.create(from: initialTodo) else {
      throw TestingError.failed("Todo creation failed")
    }

    let stream = streamProvider.createTodoStream()

    // When: Todo 수정
    var updatedTodo = createdTodo
    updatedTodo.content = "Updated Todo"
    todoService.update(updatedTodo)

    // Then: 스트림에서 .modified 이벤트 감지
    var eventReceived = false
    for await change in stream {
      if case let .modified(todo) = change, todo.fid == createdTodo.fid {
        #expect(todo.content == "Updated Todo", "수정된 Todo의 내용이 일치해야 합니다.")
        eventReceived = true
        break
      }
    }

    #expect(eventReceived == true, "Todo 수정 이벤트를 수신해야 합니다.")
  }

  @Test("Todo 삭제 시 스트림이 .removed 이벤트를 방출하는지 확인")
  func testTodoRemoved() async throws {
    // Given: 기존 Todo 생성
    let todoToDelete = Todo(
      date: Date(),
      content: "Todo to delete",
      detail: "",
      status: .todo,
      uid: userId,
      fid: "",
      lastModifiedAt: Date()
    )
    guard let createdTodo = await todoService.create(from: todoToDelete) else {
      throw TestingError.failed("Todo creation failed")
    }

    let stream = streamProvider.createTodoStream()

    // When: Todo 삭제
    todoService.remove(createdTodo)

    // Then: 스트림에서 .removed 이벤트 감지
    var eventReceived = false
    for await change in stream {
      if case let .removed(todo) = change, todo.fid == createdTodo.fid {
        #expect(todo.content == "Todo to delete", "삭제된 Todo의 내용이 일치해야 합니다.")
        eventReceived = true
        break
      }
    }

    #expect(eventReceived == true, "Todo 삭제 이벤트를 수신해야 합니다.")
  }
}
