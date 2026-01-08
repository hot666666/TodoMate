//
//  DeleteMemoUseCase.swift
//  TodoMate
//
//  Created by agent on 1/8/26.
//

protocol DeleteMemoUseCase {
  func run(for userId: String, _ memo: Memo) async throws
}

final class DeleteMemoUseCaseImpl: DeleteMemoUseCase {
  private let repository: MemoRepository

  init(repository: MemoRepository) {
    self.repository = repository
  }

  func run(for userId: String, _ memo: Memo) async throws {
    guard memo.owner == userId else { throw MemoUseCaseError.userNotAuthorized }
    try await repository.delete(memo)
  }
}

final class StubDeleteMemoUseCase: DeleteMemoUseCase {
  func run(for _: String, _ memo: Memo) async throws {
    try await StubMemoRepository().delete(memo)
  }
}
