//
//  TodoStore.swift
//  TodoMate
//
//  Created by hs on 7/9/25.
//

import Common
import SwiftUI
import TodoMateDomain

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

  init(container: PublicDIContainer) {
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
          // Cache-first: ±1달 (Wide Range) 캐시 로드
          await load(for: memberIds, range: Date().monthRange, useCache: true)
          // Server: 오늘 (Narrow Range) 최신 데이터 동기화
          await load(for: memberIds, range: Date().dayRange, useCache: false)

          Log.info(
            "Received loggedIn event, loaded todos for \(memberIds.count) users", category: .data,
          )
        case .loggedOut:
          clear()
          Log.info("Received loggedOut event, cleared todos", category: .data)
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
    await load(for: userIds, range: Date().monthRange, useCache: true)
    await load(for: userIds, range: Date().dayRange, useCache: false)
  }

  func load(for userIds: [String], range: ClosedRange<Date>, useCache: Bool = true) async {
    currentDate = .now

    do {
      let result = try await readGroupTodoUseCase.run(for: userIds, in: range, useCache: useCache)
      merge(result, in: range)
    } catch {
      Log.error("Failed to load todos for users \(userIds): \(error)", category: .data)
    }
  }

  func add(_ todo: Todo, userId: String) {
    Task {
      do {
        try await createTodoUseCase.run(for: userId, todo)
        // Optimistic update
        updateUserTodos(for: todo.owner) { userTodos in
          userTodos.append(todo)
        }
      } catch {
        Log.error("Failed to add todo: \(error)", category: .data)
      }
    }
  }

  func update(_ todo: Todo, userId: String) {
    Task {
      do {
        try await updateTodoUseCase.run(for: userId, todo)
        // Optimistic update
        updateUserTodos(for: todo.owner) { userTodos in
          if let index = userTodos.firstIndex(where: { $0.id == todo.id }) {
            userTodos[index] = todo
          }
        }
      } catch {
        Log.error("Failed to update todo: \(error)", category: .data)
      }
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
        Log.error("Failed to delete todo: \(error)", category: .data)
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

  private func merge(_ newTodos: [String: [Todo]], in range: ClosedRange<Date>) {
    for (userId, fetchedTodos) in newTodos {
      var currentTodos = todos[userId, default: []]

      // 1. Remove existing todos in the fetch range
      currentTodos.removeAll { todo in
        range.contains(todo.date)
      }

      // 2. Append new fetched todos
      currentTodos.append(contentsOf: fetchedTodos)

      // 3. Sort by date descending
      currentTodos.sort { $0.date > $1.date }

      todos[userId] = currentTodos
    }
  }
}

extension TodoStore {
  static let preview: TodoStore = {
    let store = TodoStore(container: PublicDIContainer.preview)
    store.todos = [User.stub.id: [Todo.stub]]
    return store
  }()
}
