//
//  UpdateLocalMemoUseCase.swift
//  TodoMate
//
//  Created by hs on 07/02/25.
//

protocol UpdateLocalMemoUseCase {
  func run(_ memo: Memo) async throws
}

final class UpdateLocalMemoUseCaseImpl: UpdateLocalMemoUseCase {
  private let repository: MemoRepository

  init(repository: MemoRepository) {
    self.repository = repository
  }

  func run(_ memo: Memo) async throws {
    try await repository.update(memo)
  }
}

final class StubUpdateLocalMemoUseCase: UpdateLocalMemoUseCase {
  func run(_: Memo) async throws {}
}
