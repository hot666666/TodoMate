//
//  UpdateLocalTodoUseCase.swift
//  TodoMate
//
//  Created by hs on 07/02/25.
//

import Foundation

protocol UpdateLocalTodoUseCase {
  func run(_ todo: Todo) async throws
}

final class UpdateLocalTodoUseCaseImpl: UpdateLocalTodoUseCase {
  private let repository: TodoRepository

  init(repository: TodoRepository) {
    self.repository = repository
  }

  func run(_ todo: Todo) async throws {
    try await repository.update(todo)
  }
}

final class StubUpdateLocalTodoUseCase: UpdateLocalTodoUseCase {
  func run(_: Todo) async throws {}
}
