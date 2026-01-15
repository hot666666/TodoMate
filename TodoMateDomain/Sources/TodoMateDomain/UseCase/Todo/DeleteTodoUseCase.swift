//
//  DeleteTodoUseCase.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

public protocol DeleteTodoUseCase {
  func run(for userId: String, _ todo: Todo) async throws
}

public final class DeleteTodoUseCaseImpl: DeleteTodoUseCase {
  private let repository: TodoRepository

  public init(repository: TodoRepository) {
    self.repository = repository
  }

  public func run(for userId: String, _ todo: Todo) async throws {
    guard todo.owner == userId else { throw TodoUseCaseError.userNotAuthorized }
    try await repository.delete(todo.id)
  }
}

public final class StubDeleteTodoUseCase: DeleteTodoUseCase {
  public init() {}
  public func run(for _: String, _: Todo) async throws {}
}
