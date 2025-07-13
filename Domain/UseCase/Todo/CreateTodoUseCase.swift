//
//  CreateTodoUseCase.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

protocol CreateTodoUseCase {
  func run(for userId: String, _ todo: Todo) throws
}

final class CreateTodoUseCaseImpl: CreateTodoUseCase {
  private let repository: TodoRepository

  init(repository: TodoRepository) {
    self.repository = repository
  }

  func run(for userId: String, _ todo: Todo) throws {
    guard todo.owner == userId else { throw TodoUseCaseError.userNotAuthorized }
    try repository.create(todo)
  }
}

final class StubCreateTodoUseCase: CreateTodoUseCase {
  func run(for _: String, _: Todo) throws {}
}
