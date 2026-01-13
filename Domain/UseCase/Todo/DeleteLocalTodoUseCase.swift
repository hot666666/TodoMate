//
//  DeleteLocalTodoUseCase.swift
//  TodoMate
//
//  Created by hs on 07/02/25.
//

import Foundation

protocol DeleteLocalTodoUseCase {
  func run(_ todoId: String) async throws
}

final class DeleteLocalTodoUseCaseImpl: DeleteLocalTodoUseCase {
  private let repository: TodoRepository

  init(repository: TodoRepository) {
    self.repository = repository
  }

  func run(_ todoId: String) async throws {
    try await repository.delete(todoId)
  }
}

final class StubDeleteLocalTodoUseCase: DeleteLocalTodoUseCase {
  func run(_: String) async throws {}
}
