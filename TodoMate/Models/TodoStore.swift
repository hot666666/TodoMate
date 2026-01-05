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
  private let observeGroupTodoUseCase: ObserveGroupTodoUseCase
  private let applyTodoOrderUseCase: ApplyTodoOrderUseCase
  private let reorderTodosUseCase: ReorderTodosUseCase
  private let widgetSyncService: WidgetSyncService

  // MARK: - State

  private(set) var todos: [String: [Todo]] = [:]
  private var currentDate: Date = .now

  init(container: DIContainer) {
    createTodoUseCase = container.createTodoUseCase
    readGroupTodoUseCase = container.readGroupTodoUseCase
    updateTodoUseCase = container.updateTodoUseCase
    deleteTodoUseCase = container.deleteTodoUseCase
    observeGroupTodoUseCase = container.observeGroupTodoUseCase
    applyTodoOrderUseCase = container.applyTodoOrderUseCase
    reorderTodosUseCase = container.reorderTodosUseCase
    widgetSyncService = container.widgetSyncService
  }

  // MARK: - Public Methods

  @MainActor
  func refresh(for userIds: [String], currentUserId: String) async {
    await load(for: userIds, currentUserId: currentUserId, useCache: true)
    await observe(for: userIds)
  }

  @MainActor
  func load(for userIds: [String], currentUserId: String, useCache: Bool = true) async {
    currentDate = .now

    do {
      todos = try await readGroupTodoUseCase.run(for: userIds, in: currentDate, useCache: useCache)

      updateUserTodos(for: currentUserId) { userTodos in
        userTodos = applyTodoOrderUseCase.run(todos: userTodos, currentUserId: currentUserId, currentDate: currentDate)
      }
    } catch {
      print("[TodoStore] - Failed to load todos for users \(userIds): \(error)")
      todos = [:]
    }
  }

  @MainActor
  func observe(for userIds: [String]) async {
    for await event in observeGroupTodoUseCase.run(for: userIds, in: currentDate) {
      switch event {
      case let .added(todo):
        handleTodoAdded(todo)
      case let .modified(todo):
        handleTodoModified(todo)
      case let .removed(todo):
        handleTodoRemoved(todo)
      case let .error(error):
        print("[TodoStore] - Error observing todos for users \(userIds): \(error)")
      }
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

      // Widget sync for the todo owner
      syncWidgetForUser(todo.owner)
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

  func reorderTodos(from: Int, to: Int, currentUserId: String) {
    let currentTodos = todos[currentUserId] ?? []

    updateUserTodos(for: currentUserId) { userTodos in
      userTodos = reorderTodosUseCase.run(
        todos: currentTodos,
        currentUserId: currentUserId,
        currentDate: currentDate,
        from: from,
        to: to,
      )
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

  private func syncWidgetForUser(_ userId: String) {
    Task.detached(priority: .background) { [weak self] in
      guard let self else { return }
      let userTodos = todos[userId, default: []]
      await widgetSyncService.sync(with: userTodos)
    }
  }

  private func handleTodoAdded(_ todo: Todo) {
    updateUserTodos(for: todo.owner) { userTodos in
      if let index = userTodos.firstIndex(where: { $0.id == todo.id }) {
        // 이미 존재하는데 업데이트된 경우
        if todo.updatedAt > userTodos[index].updatedAt {
          userTodos[index] = todo
        }
      } else {
        // 새로 추가된 경우
        userTodos.append(todo)
      }
    }
  }

  private func handleTodoModified(_ todo: Todo) {
    updateUserTodos(for: todo.owner) { userTodos in
      if let index = userTodos.firstIndex(where: { $0.id == todo.id }),
         todo.updatedAt > userTodos[index].updatedAt
      {
        userTodos[index] = todo
      }
    }
  }

  private func handleTodoRemoved(_ todo: Todo) {
    updateUserTodos(for: todo.owner) { userTodos in
      userTodos.removeAll { $0.id == todo.id }
    }
  }
}

extension TodoStore {
  static let preview: TodoStore = {
    let store = TodoStore(container: DIContainer.preview)
    store.todos = [User.stub.id: [Todo.stub]]
    return store
  }()
}
