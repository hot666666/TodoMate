//
//  CreateTodoUseCase.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

public protocol CreateTodoUseCase: Sendable {
  func run(for userId: String, _ todo: Todo) async throws
}

public final class CreateTodoUseCaseImpl: CreateTodoUseCase {
  private let repository: TodoRepository

  public init(repository: TodoRepository) {
    self.repository = repository
  }

  public func run(for userId: String, _ todo: Todo) async throws {
    guard todo.owner == userId else { throw TodoUseCaseError.userNotAuthorized }
    try await repository.create(todo)
  }
}

public final class StubCreateTodoUseCase: CreateTodoUseCase {
  public init() {}
  public func run(for _: String, _: Todo) async throws {}
}
