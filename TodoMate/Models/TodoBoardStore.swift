//
//  TodoBoardStore.swift
//  TodoMate
//
//  Created by hs on 07/02/25.
//
//

import Common
import Foundation
import Observation
import TodoMateDomain

@Observable
@MainActor
final class TodoBoardStore {
  var lastUpdated = Date()
  var todos: [Todo] = []

  // Dependencies
  private let createUseCase: CreateLocalTodoUseCase
  private let readUseCase: ReadLocalTodoUseCase
  private let updateUseCase: UpdateLocalTodoUseCase
  private let deleteUseCase: DeleteLocalTodoUseCase
  private let observeTodosUseCase: ObserveTodosUseCase

  private var observationTask: Task<Void, Never>?

  var error: Error?

  init(
    createUseCase: CreateLocalTodoUseCase,
    readUseCase: ReadLocalTodoUseCase,
    updateUseCase: UpdateLocalTodoUseCase,
    deleteUseCase: DeleteLocalTodoUseCase,
    observeTodosUseCase: ObserveTodosUseCase,
  ) {
    self.createUseCase = createUseCase
    self.readUseCase = readUseCase
    self.updateUseCase = updateUseCase
    self.deleteUseCase = deleteUseCase
    self.observeTodosUseCase = observeTodosUseCase

    // Start observing default range (e.g., last 7 days + future)
    // Adjust based on typical usage or user preference
    updateObservation(range: Date() ... Date().addingTimeInterval(86400 * 7))
  }

  convenience init(container: CoreDIContainer) {
    self.init(
      createUseCase: container.createLocalTodoUseCase,
      readUseCase: container.readLocalTodoUseCase,
      updateUseCase: container.updateLocalTodoUseCase,
      deleteUseCase: container.deleteLocalTodoUseCase,
      observeTodosUseCase: container.observeTodosUseCase,
    )
  }

  // MARK: - Observation

  func updateObservation(range: ClosedRange<Date>) {
    observationTask?.cancel()
    observationTask = Task {
      for await newTodos in observeTodosUseCase.execute(dateRange: range) {
        self.todos = newTodos
        self.lastUpdated = Date()
      }
    }
  }

  func getTodo(id: String) async -> Todo? {
    try? await readUseCase.run(id: id)
  }

  // MARK: - Actions

  func addTodo(_ todo: Todo) {
    Task {
      do {
        try await createUseCase.run(todo)
        self.lastUpdated = Date()
      } catch {
        self.error = error
        Log.error("Failed to create local todo: \(error)")
      }
    }
  }

  func updateTodo(_ todo: Todo) {
    Task {
      do {
        try await updateUseCase.run(todo)
        self.lastUpdated = Date()
      } catch {
        self.error = error
        Log.error("Failed to update local todo: \(error)")
      }
    }
  }

  // Status update helper
  func updateStatus(_ todo: Todo, status: TodoStatus) {
    var updatedTodo = todo
    updatedTodo.status = status
    updatedTodo.updatedAt = Date()
    updateTodo(updatedTodo)
  }

  func deleteTodo(_ todoId: String) {
    Task {
      do {
        try await deleteUseCase.run(todoId)
        self.lastUpdated = Date()
      } catch {
        self.error = error
        Log.error("Failed to delete local todo: \(error)")
      }
    }
  }

  func deleteTodo(_ todo: Todo) {
    deleteTodo(todo.id)
  }
}

extension TodoBoardStore {
  static var preview: TodoBoardStore {
    TodoBoardStore(container: .preview)
  }
}
