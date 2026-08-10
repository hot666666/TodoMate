//
//  CreateLocalTodoUseCase.swift
//  TodoMate
//
//  Created by hs on 07/02/25.
//

public protocol CreateLocalTodoUseCase: Sendable {
  func run(_ todo: Todo) async throws
}

public final class CreateLocalTodoUseCaseImpl: CreateLocalTodoUseCase {
  private let repository: TodoRepository

  public init(repository: TodoRepository) {
    self.repository = repository
  }

  public func run(_ todo: Todo) async throws {
    try await repository.create(todo)
  }
}

public final class StubCreateLocalTodoUseCase: CreateLocalTodoUseCase {
  public init() {}
  public func run(_: Todo) async throws {}
}
