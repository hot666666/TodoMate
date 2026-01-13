//
//  CreateMemoUseCase.swift
//  Todo
//
//  Created by hs on 7/8/25.
//

protocol CreateMemoUseCase {
  func run(for userId: String, _ memo: Memo) async throws
}

final class CreateMemoUseCaseImpl: CreateMemoUseCase {
  private let repository: MemoRepository

  init(repository: MemoRepository) {
    self.repository = repository
  }

  func run(for userId: String, _ memo: Memo) async throws {
    guard memo.owner == userId else { throw MemoUseCaseError.userNotAuthorized }
    try await repository.create(memo)
  }
}

final class StubCreateMemoUseCase: CreateMemoUseCase {
  func run(for _: String, _ memo: Memo) async throws {
    try await StubMemoRepository().create(memo)
  }
}
