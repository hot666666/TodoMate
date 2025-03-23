//
//  AuthManager.swift
//  TodoMate
//
//  Created by hs on 3/1/25.
//

import Observation

@Observable
final class AuthManager {
  private let fetchAUserUseCase: LoadCachedAuthenticatedUserUseCaseType
  private let signInUseCase: SignInUseCaseType
  private let signOutUseCase: SignOutUseCaseType

  private(set) var authenticatedUser: AuthenticatedUser?
  private(set) var state: State = .signedOut
  private(set) var errorLog: String?
  var showPopup: Bool = false

  init(fetchAuthenticatedUserUseCase: LoadCachedAuthenticatedUserUseCaseType,
       signInUseCase: SignInUseCaseType,
       signOutUseCase: SignOutUseCaseType) {
    fetchAUserUseCase = fetchAuthenticatedUserUseCase
    self.signInUseCase = signInUseCase
    self.signOutUseCase = signOutUseCase

    fetchAUser()
  }

  func fetchAUser() {
    guard let aUser = fetchAUserUseCase.execute() else {
      return
    }
    authenticatedUser = aUser
    state = .signedIn(aUser)
  }

  func closePopup() {
    showPopup = false
    errorLog = nil
  }

  @MainActor
  func signIn() async {
    state = .loading

    switch await signInUseCase.execute() {
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

    await signOutUseCase.execute()
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
    fetchAuthenticatedUserUseCase: StubLoadCachedAuthenticatedUserUseCase(),
    signInUseCase: StubSignInUseCase(),
    signOutUseCase: StubSignOutUseCase()
  )
}
