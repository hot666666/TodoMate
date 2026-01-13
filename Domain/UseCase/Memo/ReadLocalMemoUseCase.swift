//
//  ReadLocalMemoUseCase.swift
//  TodoMate
//
//  Created by hs on 07/02/25.
//

protocol ReadLocalMemoUseCase {
  func run() async throws -> [Memo]
}

final class ReadLocalMemoUseCaseImpl: ReadLocalMemoUseCase {
  private let repository: MemoRepository

  init(repository: MemoRepository) {
    self.repository = repository
  }

  func run() async throws -> [Memo] {
    // Local repository usually ignores userId, useCache so we pass a placeholder.
    try await repository.readAllByUserId("", useCache: false)
  }
}

final class StubReadLocalMemoUseCase: ReadLocalMemoUseCase {
  func run() async throws -> [Memo] {
    []
  }
}
