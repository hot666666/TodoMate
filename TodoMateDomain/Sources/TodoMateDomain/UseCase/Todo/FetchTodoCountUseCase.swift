//
//  FetchTodoCountUseCase.swift
//  TodoMateDomain
//
//  Created by agent on 1/16/26.
//

import Foundation

public protocol FetchTodoCountUseCase: Sendable {
  func execute(query: TodoQuery) async throws -> Int
}

public final class FetchTodoCountUseCaseImpl: FetchTodoCountUseCase {
  private let repository: TodoRepository

  public init(repository: TodoRepository) {
    self.repository = repository
  }

  public func execute(query: TodoQuery) async throws -> Int {
    try await repository.fetchCount(query: query)
  }
}
