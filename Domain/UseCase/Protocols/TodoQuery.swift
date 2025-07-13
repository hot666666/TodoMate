//
//  TodoQuery.swift
//  Todo
//
//  Created by hs on 2025/07/12.
//

import Foundation

enum TodoFilter {
  case owner(userId: String)
  case owners(userIds: [String])
  case dateRange(ClosedRange<Date>)
  case status(TodoStatus)
}

struct TodoQuery {
  private(set) var filters: [TodoFilter]

  init(filters: [TodoFilter] = []) {
    self.filters = filters
  }

  func owner(userId: String) -> TodoQuery {
    var newQuery = self
    newQuery.filters.append(.owner(userId: userId))
    return newQuery
  }

  func owners(userIds: [String]) -> TodoQuery {
    var newQuery = self
    newQuery.filters.append(.owners(userIds: userIds))
    return newQuery
  }

  func dateRange(_ range: ClosedRange<Date>) -> TodoQuery {
    var newQuery = self
    newQuery.filters.append(.dateRange(range))
    return newQuery
  }

  func status(_ status: TodoStatus) -> TodoQuery {
    var newQuery = self
    newQuery.filters.append(.status(status))
    return newQuery
  }
}
