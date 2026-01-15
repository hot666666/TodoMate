//
//  CreateLocalMemoUseCase.swift
//  TodoMate
//
//  Created by hs on 07/02/25.
//

public protocol CreateLocalMemoUseCase {
  func run(_ memo: Memo) async throws
}

public final class CreateLocalMemoUseCaseImpl: CreateLocalMemoUseCase {
  private let repository: MemoRepository

  public init(repository: MemoRepository) {
    self.repository = repository
  }

  public func run(_ memo: Memo) async throws {
    try await repository.create(memo)
  }
}

public final class StubCreateLocalMemoUseCase: CreateLocalMemoUseCase {
  public init() {}
  public func run(_: Memo) async throws {}
}
