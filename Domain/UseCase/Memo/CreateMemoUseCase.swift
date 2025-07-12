//
//  CreateMemoUseCase.swift
//  Todo
//
//  Created by hs on 7/8/25.
//

protocol CreateMemoUseCase {
  func run(for userId: String, _ memo: Memo) throws
}

final class CreateMemoUseCaseImpl: CreateMemoUseCase {
  private let repository: MemoRepository

  init(repository: MemoRepository) {
    self.repository = repository
  }

  func run(for userId: String, _ memo: Memo) throws {
    guard memo.owner == userId else { throw MemoUseCaseError.userNotAuthorized }
    try repository.create(memo)
  }
}

final class StubCreateMemoUseCase: CreateMemoUseCase {
  func run(for _: String, _ memo: Memo) throws {
    try StubMemoRepository().create(memo)
  }
}
