//
//  FetchMemoCountUseCase.swift
//  TodoMateDomain
//
//  Created by agent on 1/16/26.
//

import Foundation

public protocol FetchMemoCountUseCase: Sendable {
  func execute(userId: String) async throws -> Int
}

public final class FetchMemoCountUseCaseImpl: FetchMemoCountUseCase {
  private let repository: MemoRepository

  public init(repository: MemoRepository) {
    self.repository = repository
  }

  public func execute(userId: String) async throws -> Int {
    try await repository.fetchCount(userId: userId)
  }
}
