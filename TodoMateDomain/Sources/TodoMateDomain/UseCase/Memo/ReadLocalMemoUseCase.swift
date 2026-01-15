//
//  ReadLocalMemoUseCase.swift
//  TodoMate
//
//  Created by hs on 07/02/25.
//

public protocol ReadLocalMemoUseCase {
  func run(userId: String) async throws -> [Memo]
}

public final class ReadLocalMemoUseCaseImpl: ReadLocalMemoUseCase {
  private let repository: MemoRepository

  public init(repository: MemoRepository) {
    self.repository = repository
  }

  public func run(userId: String) async throws -> [Memo] {
    try await repository.readAllByUserId(userId, useCache: true)
  }
}

public final class StubReadLocalMemoUseCase: ReadLocalMemoUseCase {
  public init() {}
  public func run(userId _: String) async throws -> [Memo] {
    []
  }
}
