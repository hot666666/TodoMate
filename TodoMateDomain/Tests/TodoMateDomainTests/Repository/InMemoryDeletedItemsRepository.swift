//
//  InMemoryDeletedItemsRepository.swift
//  TodoMateDomain
//
//  Created by agent on 1/22/26.
//

import Foundation
@testable import TodoMateDomain

public actor InMemoryDeletedItemsRepository: DeletedItemsRepository {
  public var items: [DeletedItem] = []
  public var fetchCallCount = 0
  public var restoreCallCount = 0
  public var permanentlyDeleteCallCount = 0
  public var permanentlyDeleteAllCallCount = 0

  public init() {}

  public func setItems(_ newItems: [DeletedItem]) {
    items = newItems
  }

  public func fetchAll() async throws -> [DeletedItem] {
    fetchCallCount += 1
    // Sort by deletedAt descending (most recent first)
    return items.sorted { $0.deletedAt > $1.deletedAt }
  }

  public func restore(_ item: DeletedItem) async throws {
    restoreCallCount += 1
    items.removeAll { $0.id == item.id }
  }

  public func permanentlyDelete(_ item: DeletedItem) async throws {
    permanentlyDeleteCallCount += 1
    items.removeAll { $0.id == item.id }
  }

  public func permanentlyDeleteAll() async throws {
    permanentlyDeleteAllCallCount += 1
    items.removeAll()
  }
}
