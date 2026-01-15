//
//  CreateMemoUseCase.swift
//  Todo
//
//  Created by hs on 7/8/25.
//

public protocol CreateMemoUseCase {
  func run(for userId: String, _ memo: Memo) async throws
}

public final class CreateMemoUseCaseImpl: CreateMemoUseCase {
  private let repository: MemoRepository

  public init(repository: MemoRepository) {
    self.repository = repository
  }

  public func run(for userId: String, _ memo: Memo) async throws {
    guard memo.owner == userId else { throw MemoUseCaseError.userNotAuthorized }
    try await repository.create(memo)
  }
}

public final class StubCreateMemoUseCase: CreateMemoUseCase {
  public init() {}
  public func run(for _: String, _ memo: Memo) async throws {
    try await StubMemoRepository().create(memo)
  }
}
