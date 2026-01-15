//
//  UpdateLocalMemoUseCase.swift
//  TodoMate
//
//  Created by hs on 07/02/25.
//

public protocol UpdateLocalMemoUseCase {
  func run(_ memo: Memo) async throws
}

public final class UpdateLocalMemoUseCaseImpl: UpdateLocalMemoUseCase {
  private let repository: MemoRepository

  public init(repository: MemoRepository) {
    self.repository = repository
  }

  public func run(_ memo: Memo) async throws {
    var updatedMemo = memo
    updatedMemo.updatedAt = .now
    try await repository.update(updatedMemo)
  }
}

public final class StubUpdateLocalMemoUseCase: UpdateLocalMemoUseCase {
  public init() {}
  public func run(_: Memo) async throws {}
}
