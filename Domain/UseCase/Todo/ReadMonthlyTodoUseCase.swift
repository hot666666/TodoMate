//
//  ReadMonthlyTodoUseCase.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

import Foundation

protocol ReadMonthlyTodoUseCase {
  func run(for userId: String, range: ClosedRange<Date>, useCache: Bool) async throws -> [Todo]
}

final class ReadMonthlyTodoUseCaseImpl: ReadMonthlyTodoUseCase {
  private let repository: TodoRepository

  init(repository: TodoRepository) {
    self.repository = repository
  }

  func run(for userId: String, range: ClosedRange<Date>, useCache: Bool) async throws -> [Todo] {
    let query = TodoQuery()
      .owner(userId: userId)
      .dateRange(range)
    return try await repository.readAll(query: query, source: useCache ? .cache : .server)
  }
}

final class StubReadMonthlyTodoUseCase: ReadMonthlyTodoUseCase {
  func run(for _: String, range _: ClosedRange<Date>, useCache _: Bool) async throws -> [Todo] {
    [Todo.stub]
  }
}
