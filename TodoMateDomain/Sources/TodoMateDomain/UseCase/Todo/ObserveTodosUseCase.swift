//
//  ObserveTodosUseCase.swift
//  TodoMateDomain
//
//  Created by agent on 1/18/26.
//

import Foundation

public protocol ObserveTodosUseCase {
  func execute(dateRange: ClosedRange<Date>) -> AsyncStream<[Todo]>
}

public final class ObserveTodosUseCaseImpl: ObserveTodosUseCase {
  private let repository: TodoRepository

  public init(repository: TodoRepository) {
    self.repository = repository
  }

  public func execute(dateRange: ClosedRange<Date>) -> AsyncStream<[Todo]> {
    let query = TodoQuery().dateRange(dateRange)
    return repository.observeTodos(query: query)
  }
}

public final class StubObserveTodosUseCase: ObserveTodosUseCase {
  public init() {}
  public func execute(dateRange _: ClosedRange<Date>) -> AsyncStream<[Todo]> {
    AsyncStream { $0.finish() }
  }
}
