//
//  DeletedItem.swift
//  TodoMateDomain
//
//  Created by agent on 1/22/26.
//

import Foundation

/// A unified type representing a deleted item, which can be either a Todo or a Memo.
/// Used for displaying and managing soft-deleted items in the trash/deleted items sidebar.
public enum DeletedItem: Identifiable, Sendable, Equatable {
  case todo(Todo, snapshotRevision: Int64? = nil)
  case memo(Memo, snapshotRevision: Int64? = nil)

  public var id: String {
    switch self {
    case let .todo(todo, _): todo.id
    case let .memo(memo, _): memo.id
    }
  }

  /// The date when the item was deleted (uses updatedAt as deletion timestamp)
  public var deletedAt: Date {
    switch self {
    case let .todo(todo, _): todo.updatedAt
    case let .memo(memo, _): memo.updatedAt
    }
  }

  /// The content of the deleted item for display
  public var displayContent: String {
    switch self {
    case let .todo(todo, _): todo.contentOrPlaceholder
    case let .memo(memo, _): memo.content.isEmpty ? "빈 메모" : String(memo.content.prefix(50))
    }
  }

  /// Whether the item is a todo
  public var isTodo: Bool {
    if case .todo = self { return true }
    return false
  }

  /// Whether the item is a memo
  public var isMemo: Bool {
    if case .memo = self { return true }
    return false
  }
}
