//
//  MockTodoRepository.swift
//  TodoMateTests
//
//  Created by hs on 7/21/25.
//

import Foundation

/// Mock TodoRepository for testing
final class MockTodoRepository: TodoRepository {
  var todos: [String: [Todo]] = [:]
  var shouldThrowError = false
  var observeStream: AsyncStream<TodoRepositoryEvent>?

  func create(_ todo: Todo, for userId: String) async throws {
    if shouldThrowError {
      throw FirestoreRepositoryError.snapshotNotFound
    }
    var userTodos = todos[userId, default: []]
    userTodos.append(todo)
    todos[userId] = userTodos
  }

  func read(for userId: String, in date: Date) async throws -> [Todo] {
    if shouldThrowError {
      throw FirestoreRepositoryError.snapshotNotFound
    }
    return todos[userId, default: []]
  }

  func readGroup(for userIds: [String], in date: Date) async throws -> [String: [Todo]] {
    if shouldThrowError {
      throw FirestoreRepositoryError.snapshotNotFound
    }
    var result: [String: [Todo]] = [:]
    for userId in userIds {
      result[userId] = todos[userId, default: []]
    }
    return result
  }

  func update(_ todo: Todo, for userId: String) async throws {
    if shouldThrowError {
      throw FirestoreRepositoryError.snapshotNotFound
    }
    guard var userTodos = todos[userId],
          let index = userTodos.firstIndex(where: { $0.id == todo.id })
    else { return }

    userTodos[index] = todo
    todos[userId] = userTodos
  }

  func delete(_ todo: Todo, for userId: String) async throws {
    if shouldThrowError {
      throw FirestoreRepositoryError.snapshotNotFound
    }
    guard var userTodos = todos[userId] else { return }
    userTodos.removeAll { $0.id == todo.id }
    todos[userId] = userTodos
  }

  func observe(for userId: String, in date: Date) -> AsyncStream<TodoRepositoryEvent> {
    if let stream = observeStream {
      return stream
    }
    return AsyncStream { _ in }
  }

  func observeGroup(for userIds: [String], in date: Date) -> AsyncStream<TodoRepositoryEvent> {
    if let stream = observeStream {
      return stream
    }
    return AsyncStream { _ in }
  }
}
