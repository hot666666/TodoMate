//
//  CreateLocalTodoUseCase.swift
//  TodoMate
//
//  Created by hs on 07/02/25.
//

import Foundation

protocol CreateLocalTodoUseCase {
  func run(_ todo: Todo) async throws
}

final class CreateLocalTodoUseCaseImpl: CreateLocalTodoUseCase {
  private let repository: TodoRepository

  init(repository: TodoRepository) {
    self.repository = repository
  }

  func run(_ todo: Todo) async throws {
    try await repository.create(todo)
  }
}

final class StubCreateLocalTodoUseCase: CreateLocalTodoUseCase {
  func run(_: Todo) async throws {}
}
