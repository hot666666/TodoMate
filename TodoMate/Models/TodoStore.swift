//
//  TodoStore.swift
//  Todo
//
//  Created by hs on 7/9/25.
//

import SwiftUI

@Observable
final class TodoStore {
  // MARK: - Dependencies

  private let createTodoUseCase: CreateTodoUseCase
  private let readGroupTodoUseCase: ReadGroupTodoUseCase
  private let updateTodoUseCase: UpdateTodoUseCase
  private let deleteTodoUseCase: DeleteTodoUseCase

  // MARK: - State

  private(set) var todos: [String: [Todo]] = [:]
  private var currentDate: Date = .now

  init(container: DIContainer) {
    createTodoUseCase = container.createTodoUseCase
    readGroupTodoUseCase = container.readGroupTodoUseCase
    updateTodoUseCase = container.updateTodoUseCase
    deleteTodoUseCase = container.deleteTodoUseCase
  }

  // MARK: - Public Methods

  @MainActor
  func refresh(for userIds: [String], currentUserId: String) async {
    await load(for: userIds, currentUserId: currentUserId, useCache: true)
  }

  @MainActor
  func load(for userIds: [String], currentUserId _: String, useCache: Bool = true) async {
    currentDate = .now

    do {
      todos = try await readGroupTodoUseCase.run(for: userIds, in: currentDate, useCache: useCache)
    } catch {
      print("[TodoStore] - Failed to load todos for users \(userIds): \(error)")
      todos = [:]
    }
  }

  func add(_ todo: Todo, userId: String) {
    do {
      try createTodoUseCase.run(for: userId, todo)
      // Optimistic update
      updateUserTodos(for: todo.owner) { userTodos in
        userTodos.append(todo)
      }
    } catch {
      print("[TodoStore] - Failed to add todo: \(error)")
    }
  }

  func update(_ todo: Todo, userId: String) {
    do {
      try updateTodoUseCase.run(for: userId, todo)
      // Optimistic update
      updateUserTodos(for: todo.owner) { userTodos in
        if let index = userTodos.firstIndex(where: { $0.id == todo.id }) {
          userTodos[index] = todo
        }
      }
    } catch {
      print("[TodoStore] - Failed to update todo: \(error)")
    }
  }

  func delete(_ todo: Todo, userId: String) {
    Task {
      do {
        try await deleteTodoUseCase.run(for: userId, todo)
        // Optimistic update
        updateUserTodos(for: todo.owner) { userTodos in
          userTodos.removeAll { $0.id == todo.id }
        }
      } catch {
        print("[TodoStore] - Failed to delete todo: \(error)")
      }
    }
  }
}

extension TodoStore {
  // MARK: - Private Methods

  private func updateUserTodos(for userId: String, _ update: (inout [Todo]) -> Void) {
    var userTodos = todos[userId, default: []]
    update(&userTodos)
    todos[userId] = userTodos
  }
}

extension TodoStore {
  static let preview: TodoStore = {
    let store = TodoStore(container: DIContainer.preview)
    store.todos = [User.stub.id: [Todo.stub]]
    return store
  }()
}
