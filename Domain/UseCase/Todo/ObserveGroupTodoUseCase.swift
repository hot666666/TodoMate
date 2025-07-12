//
//  ObserveGroupTodoUseCase.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

import Foundation

protocol ObserveGroupTodoUseCase {
  func run(for userIds: [String], in date: Date) -> AsyncStream<RepositoryEvent<Todo>>
}

final class ObserveGroupTodoUseCaseImpl: ObserveGroupTodoUseCase {
  private let repository: TodoRepository

  init(repository: TodoRepository) {
    self.repository = repository
  }

  func run(for userIds: [String], in date: Date) -> AsyncStream<RepositoryEvent<Todo>> {
    let query = repository.createQuery()
      .owners(userIds: userIds)
      .dateRange(date.dayRange)
    return repository.observeAll(query: query)
  }
}

final class StubObserveGroupTodoUseCase: ObserveGroupTodoUseCase {
  func run(for _: [String], in _: Date) -> AsyncStream<RepositoryEvent<Todo>> {
    AsyncStream { continuation in
      continuation.finish()
    }
  }
}
