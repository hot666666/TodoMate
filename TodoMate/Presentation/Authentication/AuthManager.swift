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
  private(set) var errorLog: String?
  var showPopup: Bool = false

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

  func resetErrorLog() {
    errorLog = nil
  }

  @MainActor
  func signIn() async {
    state = .loading

    switch await authUseCase.signIn() {
    case let .success(aUser):
      errorLog = nil
      authenticatedUser = aUser
      state = .signedIn(aUser)
    case let .failure(.signInFailed(error)):
      errorLog = error.localizedDescription
      showPopup = true
      authenticatedUser = nil
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
