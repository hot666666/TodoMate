//
//  UpdateMemoUseCase.swift
//  Todo
//
//  Created by hs on 7/8/25.
//

public protocol UpdateMemoUseCase {
  func run(for userId: String, _ memo: Memo) async throws
}

public final class UpdateMemoUseCaseImpl: UpdateMemoUseCase {
  private let repository: MemoRepository

  public init(repository: MemoRepository) {
    self.repository = repository
  }

  public func run(for userId: String, _ memo: Memo) async throws {
    // 1. Verify ownership (optional validation)
    guard memo.owner == userId else {
      throw MemoUseCaseError.userNotAuthorized
    }

    // 2. Update
    var updatedMemo = memo
    updatedMemo.updatedAt = .now
    try await repository.update(updatedMemo)
  }
}

public final class StubUpdateMemoUseCase: UpdateMemoUseCase {
  public init() {}
  public func run(for _: String, _ memo: Memo) async throws {
    try await StubMemoRepository().update(memo)
  }
}
