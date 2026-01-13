//
//  DeleteLocalMemoUseCase.swift
//  TodoMate
//
//  Created by hs on 07/02/25.
//

protocol DeleteLocalMemoUseCase {
  func run(_ memo: Memo) async throws
}

final class DeleteLocalMemoUseCaseImpl: DeleteLocalMemoUseCase {
  private let repository: MemoRepository

  init(repository: MemoRepository) {
    self.repository = repository
  }

  func run(_ memo: Memo) async throws {
    try await repository.delete(memo)
  }
}

final class StubDeleteLocalMemoUseCase: DeleteLocalMemoUseCase {
  func run(_: Memo) async throws {}
}
