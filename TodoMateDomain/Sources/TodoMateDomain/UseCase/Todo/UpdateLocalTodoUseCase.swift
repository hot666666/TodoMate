//
//  UpdateLocalTodoUseCase.swift
//  TodoMate
//
//  Created by hs on 07/02/25.
//

public protocol UpdateLocalTodoUseCase: Sendable {
  func run(_ todo: Todo) async throws
}

public final class UpdateLocalTodoUseCaseImpl: UpdateLocalTodoUseCase {
  private let repository: TodoRepository

  public init(repository: TodoRepository) {
    self.repository = repository
  }

  public func run(_ todo: Todo) async throws {
    try await repository.update(todo)
  }
}

public final class StubUpdateLocalTodoUseCase: UpdateLocalTodoUseCase {
  public init() {}
  public func run(_: Todo) async throws {}
}
