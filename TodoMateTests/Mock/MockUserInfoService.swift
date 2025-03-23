//
//  MockUserInfoService.swift
//  TodoMate
//
//  Created by hs on 3/10/25.
//

import Foundation
@testable import TodoMate

final class MockUserInfoService: AuthenticatedUserCacheServiceType {
  private var userInfo: AuthenticatedUser?

  init(existingUserInfo: AuthenticatedUser? = nil) {
    userInfo = existingUserInfo
  }

  func save(_ userInfo: AuthenticatedUser) throws {
    self.userInfo = userInfo
  }

  func load() throws -> AuthenticatedUser {
    guard let userInfo = userInfo else {
      throw NSError(domain: "UserInfoServiceError", code: 0, userInfo: nil)
    }
    return userInfo
  }

  func clear() {
    userInfo = nil
  }
}
