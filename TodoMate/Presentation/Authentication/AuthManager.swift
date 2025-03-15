//
//  AuthManager.swift
//  TodoMate
//
//  Created by hs on 3/1/25.
//

import Observation

@Observable
final class AuthManager {
  private let authUseCase: AuthenticationUseCaseType
  private let fetchAUserUseCase: FetchAuthenticatedUserUseCaseType

  private(set) var authenticatedUser: AuthenticatedUser?
  private(set) var state: State = .signedOut

  init(authenticationUseCase: AuthenticationUseCaseType,
       fetchAuthenticatedUserUseCase: FetchAuthenticatedUserUseCaseType) {
    authUseCase = authenticationUseCase
    fetchAUserUseCase = fetchAuthenticatedUserUseCase

    fetchAUser()
  }

  func fetchAUser() {
    if let aUser = fetchAUserUseCase.execute() {
      authenticatedUser = aUser
      state = .signedIn(aUser)
    }
  }

  @MainActor
  func signIn() async {
    state = .loading

    switch await authUseCase.signIn() {
    case let .success(aUser):
      authenticatedUser = aUser
      state = .signedIn(aUser)
    case .failure:
      state = .signedOut
    }
  }

  @MainActor
  func signOut() async {
    state = .loading

    await authUseCase.signOut()
    authenticatedUser = nil
    state = .signedOut
  }
}

extension AuthManager {
  enum State {
    case signedOut
    case signedIn(AuthenticatedUser)
    case loading
  }
}

extension AuthManager {
  static let stub = AuthManager(
    authenticationUseCase: StubAuthenticationUseCase(),
    fetchAuthenticatedUserUseCase: StubFetchAuthenticatedUserUseCase()
  )
}
