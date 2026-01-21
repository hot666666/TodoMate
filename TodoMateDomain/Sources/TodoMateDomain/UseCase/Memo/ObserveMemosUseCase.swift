//
//  ObserveMemosUseCase.swift
//  TodoMateDomain
//
//  Created by agent on 1/18/26.
//

import Foundation

public protocol ObserveMemosUseCase {
  func execute() -> AsyncStream<[Memo]>
}

public final class ObserveMemosUseCaseImpl: ObserveMemosUseCase {
  private let repository: MemoRepository

  public init(repository: MemoRepository) {
    self.repository = repository
  }

  public func execute() -> AsyncStream<[Memo]> {
    repository.observeMemos()
  }
}

public final class StubObserveMemosUseCase: ObserveMemosUseCase {
  public init() {}
  public func execute() -> AsyncStream<[Memo]> {
    AsyncStream { $0.finish() }
  }
}
