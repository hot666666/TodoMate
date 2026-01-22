//
//  FetchDeletedItemsUseCase.swift
//  TodoMateDomain
//
//  Created by agent on 1/22/26.
//

/// UseCase for fetching all deleted items (todos and memos) from the trash.
/// Returns items sorted by deletion date (most recent first).
public protocol FetchDeletedItemsUseCase: Sendable {
  func run() async throws -> [DeletedItem]
}

public final class FetchDeletedItemsUseCaseImpl: FetchDeletedItemsUseCase, Sendable {
  private let repository: DeletedItemsRepository

  public init(repository: DeletedItemsRepository) {
    self.repository = repository
  }

  public func run() async throws -> [DeletedItem] {
    try await repository.fetchAll()
  }
}

public final class StubFetchDeletedItemsUseCase: FetchDeletedItemsUseCase, Sendable {
  public init() {}
  public func run() async throws -> [DeletedItem] { [] }
}
