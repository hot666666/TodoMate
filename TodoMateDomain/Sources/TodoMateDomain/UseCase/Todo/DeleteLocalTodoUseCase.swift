//
//  DeleteLocalTodoUseCase.swift
//  TodoMate
//
//  Created by hs on 07/02/25.
//

public protocol DeleteLocalTodoUseCase: Sendable {
  func run(_ todoId: String) async throws
}

public final class DeleteLocalTodoUseCaseImpl: DeleteLocalTodoUseCase {
  private let repository: TodoRepository

  public init(repository: TodoRepository) {
    self.repository = repository
  }

  public func run(_ todoId: String) async throws {
    try await repository.delete(todoId)
  }
}

public final class StubDeleteLocalTodoUseCase: DeleteLocalTodoUseCase {
  public init() {}
  public func run(_: String) async throws {}
}
