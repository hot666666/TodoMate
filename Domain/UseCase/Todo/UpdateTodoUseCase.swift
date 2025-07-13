//
//  UpdateTodoUseCase.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

protocol UpdateTodoUseCase {
  func run(for userId: String, _ todo: Todo) throws
}

final class UpdateTodoUseCaseImpl: UpdateTodoUseCase {
  private let repository: TodoRepository

  init(repository: TodoRepository) {
    self.repository = repository
  }

  func run(for userId: String, _ todo: Todo) throws {
    guard todo.owner == userId else { throw TodoUseCaseError.userNotAuthorized }
    try repository.update(todo)
  }
}

final class StubUpdateTodoUseCase: UpdateTodoUseCase {
  func run(for _: String, _: Todo) throws {}
}
