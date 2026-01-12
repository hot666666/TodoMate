//
//  UpdateMemoUseCase.swift
//  Todo
//
//  Created by hs on 7/8/25.
//

protocol UpdateMemoUseCase {
  func run(for userId: String, _ memo: Memo) async throws
}

final class UpdateMemoUseCaseImpl: UpdateMemoUseCase {
  private let repository: MemoRepository

  init(repository: MemoRepository) {
    self.repository = repository
  }

  func run(for userId: String, _ memo: Memo) async throws {
    guard memo.owner == userId else { throw MemoUseCaseError.userNotAuthorized }
    try await repository.update(memo)
  }
}

final class StubUpdateMemoUseCase: UpdateMemoUseCase {
  func run(for _: String, _ memo: Memo) async throws {
    try await StubMemoRepository().update(memo)
  }
}
