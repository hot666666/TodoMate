//
//  TodoStore.swift
//  TodoMate
//
//  Created by hs on 7/9/25.
//

import SwiftUI

@Observable
@MainActor
final class TodoStore {
  // MARK: - Dependencies

  private let createTodoUseCase: CreateTodoUseCase
  private let readGroupTodoUseCase: ReadGroupTodoUseCase
  private let updateTodoUseCase: UpdateTodoUseCase
  private let deleteTodoUseCase: DeleteTodoUseCase

  // MARK: - Listener

  @ObservationIgnored private var listener: Task<Void, Never>?

  // MARK: - State

  private(set) var todos: [String: [Todo]] = [:]
  private var currentDate: Date = .now
  private var currentUserId: String = ""

  init(container: DIContainer) {
    createTodoUseCase = container.createTodoUseCase
    readGroupTodoUseCase = container.readGroupTodoUseCase
    updateTodoUseCase = container.updateTodoUseCase
    deleteTodoUseCase = container.deleteTodoUseCase
  }

  // MARK: - Subscriber

  /// SessionStore 이벤트 구독 시작
  func startListening(to events: AsyncStream<SessionEvent>) {
    listener?.cancel()
    listener = Task { [weak self] in
      for await event in events {
        guard let self else { return }
        switch event {
        case let .loggedIn(userId, _, memberIds):
          currentUserId = userId
          // Cache-first: 먼저 캐시에서 빠르게 로드 (오프라인 지원)
          await load(for: memberIds, useCache: true)
          // 그 다음 서버에서 최신 데이터로 업데이트
          await load(for: memberIds, useCache: false)
          print("[TodoStore] - Received loggedIn event, loaded todos for \(memberIds.count) users")
        case .loggedOut:
          clear()
          print("[TodoStore] - Received loggedOut event, cleared todos")
        }
      }
    }
  }

  /// 리스너 정리
  func cleanup() {
    listener?.cancel()
    listener = nil
  }

  // MARK: - Public Methods

  func refresh(for userIds: [String]) async {
    await load(for: userIds, useCache: true)
  }

  func load(for userIds: [String], useCache: Bool = true) async {
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

  func clear() {
    todos = [:]
    currentUserId = ""
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
