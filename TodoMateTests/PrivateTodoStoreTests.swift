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
    var runHandler: ((Todo) -> Void)?
    func run(_ todo: Todo) async throws { runHandler?(todo) }
  }

  final class MockReadUseCase: ReadLocalTodoUseCase {
    func run(date _: Date) async throws -> [Todo] { [] }
    func run(in _: ClosedRange<Date>) async throws -> [Todo] { [] }
    func run(id _: String) async throws -> Todo? { nil }
  }

  final class MockUpdateUseCase: UpdateLocalTodoUseCase {
    var runHandler: ((Todo) -> Void)?
    func run(_ todo: Todo) async throws { runHandler?(todo) }
  }

  final class MockDeleteUseCase: DeleteLocalTodoUseCase {
    var runHandler: ((String) -> Void)?
    func run(_ todoId: String) async throws { runHandler?(todoId) }
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
    var capturedTodo: Todo?
    createUC.runHandler = { capturedTodo = $0 }

    // When
    store.addTodo(todo)
    try await Task.sleep(for: .milliseconds(50))

    // Then
    #expect(capturedTodo?.id == todo.id)
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
    var capturedTodo: Todo?
    updateUC.runHandler = { capturedTodo = $0 }

    // When
    store.updateTodo(todo)
    try await Task.sleep(for: .milliseconds(50))

    // Then
    #expect(capturedTodo?.id == todo.id)
    #expect(capturedTodo?.content == "Updated Todo")
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
    var capturedId: String?
    deleteUC.runHandler = { capturedId = $0 }

    // When
    store.deleteTodo(todoId)
    try await Task.sleep(for: .milliseconds(50))

    // Then
    #expect(capturedId == todoId)
  }
}
