//
//  TodoQuery.swift
//  Todo
//
//  Created by hs on 2025/07/12.
//

import Foundation

public enum TodoFilter: Sendable {
  case owner(userId: String)
  case owners(userIds: [String])
  case dateRange(ClosedRange<Date>)
  case status(TodoStatus)
}

public struct TodoQuery: Sendable {
  public private(set) var filters: [TodoFilter]

  public init(filters: [TodoFilter] = []) {
    self.filters = filters
  }

  public func owner(userId: String) -> TodoQuery {
    var newQuery = self
    newQuery.filters.append(.owner(userId: userId))
    return newQuery
  }

  public func owners(userIds: [String]) -> TodoQuery {
    var newQuery = self
    newQuery.filters.append(.owners(userIds: userIds))
    return newQuery
  }

  public func dateRange(_ range: ClosedRange<Date>) -> TodoQuery {
    var newQuery = self
    newQuery.filters.append(.dateRange(range))
    return newQuery
  }

  public func status(_ status: TodoStatus) -> TodoQuery {
    var newQuery = self
    newQuery.filters.append(.status(status))
    return newQuery
  }
}
