//
//  RestoreDeletedItemUseCase.swift
//  TodoMateDomain
//
//  Created by agent on 1/22/26.
//

/// UseCase for restoring deleted items back to their original state.
/// Sets isDeleted = false for the specified items.
public protocol RestoreDeletedItemUseCase: Sendable {
  /// Restore a single deleted item
  func run(_ item: DeletedItem) async throws

  /// Restore multiple deleted items
  func run(_ items: [DeletedItem]) async throws
}

public final class RestoreDeletedItemUseCaseImpl: RestoreDeletedItemUseCase, Sendable {
  private let repository: DeletedItemsRepository

  public init(repository: DeletedItemsRepository) {
    self.repository = repository
  }

  public func run(_ item: DeletedItem) async throws {
    try await repository.restore(item)
  }

  public func run(_ items: [DeletedItem]) async throws {
    for item in items {
      try await repository.restore(item)
    }
  }
}

public final class StubRestoreDeletedItemUseCase: RestoreDeletedItemUseCase, Sendable {
  public init() {}
  public func run(_: DeletedItem) async throws {}
  public func run(_: [DeletedItem]) async throws {}
}
