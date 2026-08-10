//
//  UpdateTodoUseCase.swift
//  TodoMate
//
//
//  Created by hs on 6/30/25.
//

import Common
import Foundation

public protocol UpdateTodoUseCase: Sendable {
  func run(for userId: String, _ todo: Todo) async throws
}

public final class UpdateTodoUseCaseImpl: UpdateTodoUseCase {
  private let repository: TodoRepository

  public init(repository: TodoRepository) {
    self.repository = repository
  }

  public func run(for userId: String, _ todo: Todo) async throws {
    guard todo.owner == userId else { throw TodoUseCaseError.userNotAuthorized }
    try await repository.update(todo)
  }
}

public final class StubUpdateTodoUseCase: UpdateTodoUseCase {
  public init() {}
  public func run(for _: String, _: Todo) async throws {}
}
