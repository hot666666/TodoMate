//
//  ReadGroupTodoUseCase.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

import Foundation

public protocol ReadGroupTodoUseCase: Sendable {
  func run(for userIds: [String], in range: ClosedRange<Date>, useCache: Bool) async throws
    -> [String: [Todo]]
}

public final class ReadGroupTodoUseCaseImpl: ReadGroupTodoUseCase {
  private let repository: TodoRepository

  public init(repository: TodoRepository) {
    self.repository = repository
  }

  public func run(for userIds: [String], in range: ClosedRange<Date>, useCache: Bool) async throws
    -> [String: [Todo]] {
    let query = TodoQuery()
      .owners(userIds: userIds)
      .dateRange(range)
    let result = try await repository.readAll(query: query, useCache: useCache)
    let groupedResult = Dictionary(grouping: result) { $0.owner }
    return Dictionary(
      uniqueKeysWithValues: userIds.map { userId in (userId, groupedResult[userId] ?? []) })
  }
}

public final class StubReadGroupTodoUseCase: ReadGroupTodoUseCase {
  public init() {}
  public func run(for userIds: [String], in _: ClosedRange<Date>, useCache _: Bool) async throws
    -> [String: [Todo]] {
    Dictionary(uniqueKeysWithValues: userIds.map { userId in (userId, []) })
  }
}
