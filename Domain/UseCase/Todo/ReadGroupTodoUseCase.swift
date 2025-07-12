//
//  ReadGroupTodoUseCase.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

import Foundation

protocol ReadGroupTodoUseCase {
  func run(for userIds: [String], in date: Date, useCache: Bool) async throws -> [String: [Todo]]
}

final class ReadGroupTodoUseCaseImpl: ReadGroupTodoUseCase {
  private let repository: TodoRepository

  init(repository: TodoRepository) {
    self.repository = repository
  }

  func run(for userIds: [String], in date: Date, useCache: Bool) async throws -> [String: [Todo]] {
    let query = repository.createQuery()
      .owners(userIds: userIds)
      .dateRange(date.dayRange)
    let result = try await repository.readAll(query: query, source: useCache ? .cache : .server)
    let groupedResult = Dictionary(grouping: result) { $0.owner }
    return Dictionary(uniqueKeysWithValues: userIds.map { userId in (userId, groupedResult[userId] ?? []) })
  }
}

final class StubReadGroupTodoUseCase: ReadGroupTodoUseCase {
  func run(for userIds: [String], in _: Date, useCache _: Bool) async throws -> [String: [Todo]] {
    Dictionary(uniqueKeysWithValues: userIds.map { userId in (userId, []) })
  }
}
