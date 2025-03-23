//
//  MockAuthenticatedUserCacheService.swift
//  TodoMate
//
//  Created by hs on 3/23/25.
//

import Foundation
@testable import TodoMate

final class MockAuthenticatedUserCacheService: AuthenticatedUserCacheServiceType {
  var cachedUser: AuthenticatedUser?
  var isCleared: Bool = false

  func save(_ userInfo: AuthenticatedUser) throws {
    cachedUser = userInfo
    isCleared = false
  }

  func load() throws -> AuthenticatedUser {
    guard let user = cachedUser else {
      throw NSError(domain: "No cached user", code: 0)
    }
    return user
  }

  func clear() {
    cachedUser = nil
    isCleared = true
  }
}
