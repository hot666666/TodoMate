//
//  UpdateTodoUseCase.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

protocol UpdateTodoUseCase {
  func run(for userId: String, _ todo: Todo) async throws
}

final class UpdateTodoUseCaseImpl: UpdateTodoUseCase {
  private let repository: TodoRepository

  init(repository: TodoRepository) {
    self.repository = repository
  }

  func run(for userId: String, _ todo: Todo) async throws {
    guard todo.owner == userId else { throw TodoUseCaseError.userNotAuthorized }
    try await repository.update(todo)
  }
}

final class StubUpdateTodoUseCase: UpdateTodoUseCase {
  func run(for _: String, _: Todo) async throws {}
}
