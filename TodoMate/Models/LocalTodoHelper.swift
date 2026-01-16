//
//  LocalTodoHelper.swift
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
final class LocalTodoHelper {
  private let createUseCase: CreateLocalTodoUseCase
  private let readUseCase: ReadLocalTodoUseCase
  private let updateUseCase: UpdateLocalTodoUseCase
  private let deleteUseCase: DeleteLocalTodoUseCase

  var error: Error?

  init(
    createUseCase: CreateLocalTodoUseCase,
    readUseCase: ReadLocalTodoUseCase,
    updateUseCase: UpdateLocalTodoUseCase,
    deleteUseCase: DeleteLocalTodoUseCase,
  ) {
    self.createUseCase = createUseCase
    self.readUseCase = readUseCase
    self.updateUseCase = updateUseCase
    self.deleteUseCase = deleteUseCase
  }

  convenience init(container: CoreDIContainer) {
    self.init(
      createUseCase: container.createLocalTodoUseCase,
      readUseCase: container.readLocalTodoUseCase,
      updateUseCase: container.updateLocalTodoUseCase,
      deleteUseCase: container.deleteLocalTodoUseCase,
    )
  }

  // MARK: - Actions

  func addTodo(_ todo: Todo) {
    Task {
      do {
        try await createUseCase.run(todo)
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

extension LocalTodoHelper {
  static var preview: LocalTodoHelper {
    LocalTodoHelper(container: .preview)
  }
}
