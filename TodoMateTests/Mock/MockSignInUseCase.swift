//
//  MockSignInUseCase.swift
//  TodoMate
//
//  Created by hs on 3/23/25.
//

import Foundation
@testable import TodoMate

final class MockSignInUseCase: SignInUseCaseType {
  private let shouldSignInSuccess: Bool
  private let signInReturn: AuthenticatedUser?
  private let error: Error?

  init(shouldSignInSuccess: Bool, signInReturn: AuthenticatedUser? = nil, error: Error? = nil) {
    self.shouldSignInSuccess = shouldSignInSuccess
    self.signInReturn = signInReturn
    self.error = error
  }

  func execute() async -> Result<AuthenticatedUser, SignInUseCaseError> {
    if shouldSignInSuccess, let user = signInReturn {
      return .success(user)
    } else {
      return .failure(.signInFailed(error ?? NSError(domain: "MockError", code: -1, userInfo: nil)))
    }
  }
}
