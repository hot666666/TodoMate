//
//  MockUserGroupCacheService.swift
//  TodoMate
//
//  Created by hs on 3/23/25.
//

@testable import TodoMate

final class MockUserGroupCacheService: UserGroupCacheServiceType {
  private var cachedUsers: [User] = []
  var isCleared: Bool = false

  func load() throws -> [User] {
    return cachedUsers
  }

  func save(_ users: [User]) throws {
    cachedUsers = users
    isCleared = false
  }

  func clear() {
    cachedUsers = []
    isCleared = true
  }
}
