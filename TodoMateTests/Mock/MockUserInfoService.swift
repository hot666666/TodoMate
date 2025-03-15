//
//  MockUserInfoService.swift
//  TodoMate
//
//  Created by hs on 3/10/25.
//

import Foundation
@testable import TodoMate

final class MockUserInfoService: UserInfoServiceType {
  private var userInfo: AuthenticatedUser?

  init(existingUserInfo: AuthenticatedUser? = nil) {
    userInfo = existingUserInfo
  }

  func saveUserInfo(_ userInfo: AuthenticatedUser) throws {
    self.userInfo = userInfo
  }

  func loadUserInfo() throws -> AuthenticatedUser {
    guard let userInfo = userInfo else {
      throw NSError(domain: "UserInfoServiceError", code: 0, userInfo: nil)
    }
    return userInfo
  }

  func clearUserInfo() {
    userInfo = nil
  }
}
