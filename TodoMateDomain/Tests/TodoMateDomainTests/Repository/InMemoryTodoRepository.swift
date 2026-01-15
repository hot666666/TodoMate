//
//  InMemoryTodoRepository.swift
//  TodoMateDomain
//
//  Created by agent on 1/14/26.
//

import Foundation
@testable import TodoMateDomain

public actor InMemoryTodoRepository: TodoRepository {
  public var todos: [Todo] = []
  public var createCallCount = 0
  public var updateCallCount = 0
  public var deleteCallCount = 0
  public var readCallCount = 0
  public var lastQuery: TodoQuery?

  public init() {}

  public func create(_ todo: Todo) async throws {
    createCallCount += 1
    todos.append(todo)
  }

  public func update(_ todo: Todo) async throws {
    updateCallCount += 1
    if let index = todos.firstIndex(where: { $0.id == todo.id }) {
      todos[index] = todo
    }
  }

  public func delete(_ todoId: String) async throws {
    deleteCallCount += 1
    todos.removeAll { $0.id == todoId }
  }

  public func setTodos(_ newTodos: [Todo]) {
    todos = newTodos
  }

  public func readAll(query: TodoQuery, useCache _: Bool) async throws -> [Todo] {
    readCallCount += 1
    lastQuery = query

    // Simple in-memory filter
    return todos.filter { todo in
      for filter in query.filters {
        switch filter {
        case let .dateRange(range):
          if !range.contains(todo.date) { return false }
        case let .owner(userId):
          if todo.owner != userId { return false }
        default: continue
        }
      }
      return true
    }
  }
}
