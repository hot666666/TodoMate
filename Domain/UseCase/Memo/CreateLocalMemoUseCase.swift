//
//  CreateLocalMemoUseCase.swift
//  TodoMate
//
//  Created by hs on 07/02/25.
//

protocol CreateLocalMemoUseCase {
  func run(_ memo: Memo) async throws
}

final class CreateLocalMemoUseCaseImpl: CreateLocalMemoUseCase {
  private let repository: MemoRepository

  init(repository: MemoRepository) {
    self.repository = repository
  }

  func run(_ memo: Memo) async throws {
    try await repository.create(memo)
  }
}

final class StubCreateLocalMemoUseCase: CreateLocalMemoUseCase {
  func run(_: Memo) async throws {}
}
