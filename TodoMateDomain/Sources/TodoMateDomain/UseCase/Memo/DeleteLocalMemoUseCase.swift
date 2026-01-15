//
//  DeleteLocalMemoUseCase.swift
//  TodoMate
//
//  Created by hs on 07/02/25.
//

public protocol DeleteLocalMemoUseCase {
  func run(_ memo: Memo) async throws
}

public final class DeleteLocalMemoUseCaseImpl: DeleteLocalMemoUseCase {
  private let repository: MemoRepository

  public init(repository: MemoRepository) {
    self.repository = repository
  }

  public func run(_ memo: Memo) async throws {
    try await repository.delete(memo)
  }
}

public final class StubDeleteLocalMemoUseCase: DeleteLocalMemoUseCase {
  public init() {}
  public func run(_: Memo) async throws {}
}
