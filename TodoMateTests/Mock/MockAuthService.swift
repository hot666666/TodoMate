//
//  MockAuthService.swift
//  TodoMate
//
//  Created by hs on 3/10/25.
//

import Foundation
@testable import TodoMate

struct MockAuthService: AuthServiceType {
  private let shouldSignInSuccess: Bool
  private let signInReturn: User?

  init(shouldSignInSuccess: Bool = false, signInReturn: User? = nil) {
    self.shouldSignInSuccess = shouldSignInSuccess
    self.signInReturn = signInReturn
  }

  func signIn() async throws -> User {
    if shouldSignInSuccess {
      return signInReturn ?? .stub[0]
    } else {
      throw NSError(domain: "AuthError", code: 0, userInfo: nil)
    }
  }

  func signOut() async {}
}
