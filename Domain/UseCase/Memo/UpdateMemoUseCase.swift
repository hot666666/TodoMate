//
//  UpdateMemoUseCase.swift
//  Todo
//
//  Created by hs on 7/8/25.
//

protocol UpdateMemoUseCase {
  func run(for userId: String, _ memo: Memo) throws
}

final class UpdateMemoUseCaseImpl: UpdateMemoUseCase {
  private let repository: MemoRepository

  init(repository: MemoRepository) {
    self.repository = repository
  }

  func run(for userId: String, _ memo: Memo) throws {
    guard memo.owner == userId else { throw MemoUseCaseError.userNotAuthorized }
    try repository.update(memo)
  }
}

final class StubUpdateMemoUseCase: UpdateMemoUseCase {
  func run(for _: String, _ memo: Memo) throws {
    try StubMemoRepository().update(memo)
  }
}
