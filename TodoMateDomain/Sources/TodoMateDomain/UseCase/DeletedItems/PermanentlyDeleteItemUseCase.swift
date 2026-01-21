//
//  PermanentlyDeleteItemUseCase.swift
//  TodoMateDomain
//
//  Created by agent on 1/22/26.
//

/// UseCase for permanently deleting items from storage.
/// This removes items completely, not just soft-delete.
public protocol PermanentlyDeleteItemUseCase: Sendable {
  /// Permanently delete a single item
  func run(_ item: DeletedItem) async throws

  /// Permanently delete multiple items
  func run(_ items: [DeletedItem]) async throws

  /// Permanently delete all items (empty trash)
  func runAll() async throws
}

public final class PermanentlyDeleteItemUseCaseImpl: PermanentlyDeleteItemUseCase, Sendable {
  private let repository: DeletedItemsRepository

  public init(repository: DeletedItemsRepository) {
    self.repository = repository
  }

  public func run(_ item: DeletedItem) async throws {
    try await repository.permanentlyDelete(item)
  }

  public func run(_ items: [DeletedItem]) async throws {
    for item in items {
      try await repository.permanentlyDelete(item)
    }
  }

  public func runAll() async throws {
    try await repository.permanentlyDeleteAll()
  }
}

public final class StubPermanentlyDeleteItemUseCase: PermanentlyDeleteItemUseCase, Sendable {
  public init() {}
  public func run(_: DeletedItem) async throws {}
  public func run(_: [DeletedItem]) async throws {}
  public func runAll() async throws {}
}
