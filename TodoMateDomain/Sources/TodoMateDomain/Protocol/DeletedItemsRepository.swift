//
//  DeletedItemsRepository.swift
//  TodoMateDomain
//
//  Created by agent on 1/22/26.
//

/// Repository protocol for managing soft-deleted items (both Todo and Memo).
/// Handles fetching, restoring, and permanently deleting items from the trash.
public protocol DeletedItemsRepository: Sendable {
  /// Fetches all deleted items (both todos and memos)
  func fetchAll() async throws -> [DeletedItem]

  /// Restores a deleted item by setting isDeleted = false
  func restore(_ item: DeletedItem) async throws

  /// Permanently deletes an item from storage
  func permanentlyDelete(_ item: DeletedItem) async throws

  /// Permanently deletes all items (empties the trash)
  func permanentlyDeleteAll() async throws
}

// MARK: - StubDeletedItemsRepository

public final class StubDeletedItemsRepository: DeletedItemsRepository, Sendable {
  public init() {}
  public func fetchAll() async throws -> [DeletedItem] { [] }
  public func restore(_: DeletedItem) async throws {}
  public func permanentlyDelete(_: DeletedItem) async throws {}
  public func permanentlyDeleteAll() async throws {}
}
