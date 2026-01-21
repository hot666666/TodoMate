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
  private let createUseCase: CreateLocalTodoUseCase
  private let readUseCase: ReadLocalTodoUseCase
  private let updateUseCase: UpdateLocalTodoUseCase
  private let deleteUseCase: DeleteLocalTodoUseCase
  private let observeTodosUseCase: ObserveTodosUseCase

  private var observationTask: Task<Void, Never>?

  var todos: [Todo] = []
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

    startObservation()
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

  func startObservation() {
    observationTask?.cancel()

    let endDate = Date().startOfDay
    let startDate = endDate.addingTimeInterval(86400 * -7)

    observationTask = Task { [weak self] in
      guard let self else { return }

      let todoStream = observeTodosUseCase.execute(dateRange: startDate ... endDate)

      await withTaskGroup(of: Void.self) { group in
        group.addTask {
          for await newTodos in todoStream {
            await MainActor.run {
              self.todos = newTodos
            }
          }
        }

        group.addTask {
          let dayChangeStream = NotificationCenter.default.notifications(named: .NSCalendarDayChanged)
          for await _ in dayChangeStream {
            await MainActor.run {
              self.startObservation()
            }
            return
          }
        }
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

  func duplicate(_ todo: Todo) {
    var newTodo = Todo.copy(from: todo)
    newTodo.detail = ""
    addTodo(newTodo)
  }
}

extension TodoBoardStore {
  static var preview: TodoBoardStore {
    TodoBoardStore(container: .preview)
  }
}
