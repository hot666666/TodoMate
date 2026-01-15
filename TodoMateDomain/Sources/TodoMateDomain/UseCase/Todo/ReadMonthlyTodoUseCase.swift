//
//  ReadMonthlyTodoUseCase.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

import Foundation

public protocol ReadMonthlyTodoUseCase {
  func run(for userId: String, range: ClosedRange<Date>, useCache: Bool) async throws -> [Todo]
}

public final class ReadMonthlyTodoUseCaseImpl: ReadMonthlyTodoUseCase {
  private let repository: TodoRepository

  public init(repository: TodoRepository) {
    self.repository = repository
  }

  public func run(for userId: String, range: ClosedRange<Date>, useCache: Bool) async throws -> [Todo] {
    let query = TodoQuery()
      .owner(userId: userId)
      .dateRange(range)
    return try await repository.readAll(query: query, useCache: useCache)
  }
}

public final class StubReadMonthlyTodoUseCase: ReadMonthlyTodoUseCase {
  public init() {}
  public func run(for _: String, range _: ClosedRange<Date>, useCache _: Bool) async throws -> [Todo] {
    [Todo.stub]
  }
}
