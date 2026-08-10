//
//  PrivateTodoStoreTests.swift
//  TodoMateTests
//
//  Created by agent on 1/12/26.
//
//

import Foundation
import Testing
import TodoMateDomain

@testable import TodoMate

@Suite("PrivateTodoStore Unit Tests")
@MainActor
struct PrivateTodoStoreTests {
  // MARK: - Mock UseCases

  final class MockCreateUseCase: CreateLocalTodoUseCase {
    private let invocation = AwaitableInvocation<Todo>()

    func nextInvocation() async throws -> Todo {
      try await invocation.next()
    }

    func run(_ todo: Todo) async throws {
      invocation.record(todo)
    }
  }

  final class MockReadUseCase: ReadLocalTodoUseCase {
    func run(date _: Date) async throws -> [Todo] { [] }
    func run(in _: ClosedRange<Date>) async throws -> [Todo] { [] }
    func run(id _: String) async throws -> Todo? { nil }
  }

  final class MockUpdateUseCase: UpdateLocalTodoUseCase {
    private let invocation = AwaitableInvocation<Todo>()

    func nextInvocation() async throws -> Todo {
      try await invocation.next()
    }

    func run(_ todo: Todo) async throws {
      invocation.record(todo)
    }
  }

  final class MockDeleteUseCase: DeleteLocalTodoUseCase {
    private let invocation = AwaitableInvocation<String>()

    func nextInvocation() async throws -> String {
      try await invocation.next()
    }

    func run(_ todoId: String) async throws {
      invocation.record(todoId)
    }
  }

  final class MockObserveUseCase: ObserveTodosUseCase {
    func execute(dateRange _: ClosedRange<Date>) -> AsyncStream<[Todo]> {
      AsyncStream { continuation in
        continuation.finish()
      }
    }
  }

  @Test("Add Todo calls CreateUseCase")
  func addTodo_callsUseCase() async throws {
    // Given
    let createUC = MockCreateUseCase()
    let readUC = MockReadUseCase()
    let updateUC = MockUpdateUseCase()
    let deleteUC = MockDeleteUseCase()

    let observeUC = MockObserveUseCase()

    let store = TodoBoardStore(
      createUseCase: createUC,
      readUseCase: readUC,
      updateUseCase: updateUC,
      deleteUseCase: deleteUC,
      observeTodosUseCase: observeUC,
    )

    let todo = Todo(owner: "me", content: "New Todo", in: Date())
    // When
    store.addTodo(todo)
    let receivedTodo = try await createUC.nextInvocation()

    // Then
    #expect(receivedTodo.id == todo.id)
  }

  @Test("Update Todo calls UpdateUseCase")
  func updateTodo_callsUseCase() async throws {
    // Given
    let createUC = MockCreateUseCase()
    let readUC = MockReadUseCase()
    let updateUC = MockUpdateUseCase()
    let deleteUC = MockDeleteUseCase()

    let observeUC = MockObserveUseCase()

    let store = TodoBoardStore(
      createUseCase: createUC,
      readUseCase: readUC,
      updateUseCase: updateUC,
      deleteUseCase: deleteUC,
      observeTodosUseCase: observeUC,
    )

    let todo = Todo(owner: "me", content: "Updated Todo", in: Date())
    // When
    store.updateTodo(todo)
    let receivedTodo = try await updateUC.nextInvocation()

    // Then
    #expect(receivedTodo.id == todo.id)
    #expect(receivedTodo.content == "Updated Todo")
  }

  @Test("Delete Todo calls DeleteUseCase")
  func deleteTodo_callsUseCase() async throws {
    // Given
    let createUC = MockCreateUseCase()
    let readUC = MockReadUseCase()
    let updateUC = MockUpdateUseCase()
    let deleteUC = MockDeleteUseCase()

    let observeUC = MockObserveUseCase()

    let store = TodoBoardStore(
      createUseCase: createUC,
      readUseCase: readUC,
      updateUseCase: updateUC,
      deleteUseCase: deleteUC,
      observeTodosUseCase: observeUC,
    )

    let todoId = "some-id"
    // When
    store.deleteTodo(todoId)
    let receivedTodoID = try await deleteUC.nextInvocation()

    // Then
    #expect(receivedTodoID == todoId)
  }
}
