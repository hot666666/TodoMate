//
//  DeleteMemoUseCase.swift
//  TodoMate
//
//  Created by agent on 1/8/26.
//

public protocol DeleteMemoUseCase {
  func run(for userId: String, _ memo: Memo) async throws
}

public final class DeleteMemoUseCaseImpl: DeleteMemoUseCase {
  private let repository: MemoRepository

  public init(repository: MemoRepository) {
    self.repository = repository
  }

  public func run(for userId: String, _ memo: Memo) async throws {
    // 1. Verify ownership
    guard memo.owner == userId else { throw MemoUseCaseError.userNotAuthorized }

    // 2. Delete
    try await repository.delete(memo)
  }
}

public final class StubDeleteMemoUseCase: DeleteMemoUseCase {
  public init() {}
  public func run(for _: String, _ memo: Memo) async throws {
    try await StubMemoRepository().delete(memo)
  }
}
