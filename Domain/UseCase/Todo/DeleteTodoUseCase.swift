//
//  DeleteTodoUseCase.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

protocol DeleteTodoUseCase {
  func run(for userId: String, _ todo: Todo) async throws
}

final class DeleteTodoUseCaseImpl: DeleteTodoUseCase {
  private let repository: TodoRepository

  init(repository: TodoRepository) {
    self.repository = repository
  }

  func run(for userId: String, _ todo: Todo) async throws {
    guard todo.owner == userId else { throw TodoUseCaseError.userNotAuthorized }
    try await repository.delete(todo.id)
  }
}

final class StubDeleteTodoUseCase: DeleteTodoUseCase {
  func run(for _: String, _: Todo) async throws {}
}
