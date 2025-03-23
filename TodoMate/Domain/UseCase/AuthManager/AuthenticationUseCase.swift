//
//  AuthenticationUseCase.swift
//  TodoMate
//
//  Created by hs on 3/6/25.
//

enum AuthenticationUseCaseError: Error {
  case signInFailed(Error)
}

protocol AuthenticationUseCaseType {
  func signOut() async
  func signIn() async -> Result<AuthenticatedUser, AuthenticationUseCaseError>
}

final class AuthenticationUseCase: AuthenticationUseCaseType {
  private let authService: AuthServiceType
  private let userInfoService: AuthenticatedUserCacheServiceType
  private let widgetDataManager: WidgetDataManagerType

  init(authService: AuthServiceType, userInfoService: AuthenticatedUserCacheServiceType,
       widgetDataManager: WidgetDataManagerType) {
    self.authService = authService
    self.userInfoService = userInfoService
    self.widgetDataManager = widgetDataManager
  }

  func signOut() async {
    await authService.signOut()
    userInfoService.clear()
    await widgetDataManager.removeAll()
  }

  func signIn() async -> Result<AuthenticatedUser, AuthenticationUseCaseError> {
    userInfoService.clear()
    do {
      let signedInUser = try await authService.signIn()
      let authenticatedUser = AuthenticatedUser.from(signedInUser)
      try userInfoService.save(authenticatedUser)
      return .success(authenticatedUser)
    } catch {
      return .failure(.signInFailed(error))
    }
  }
}

class StubAuthenticationUseCase: AuthenticationUseCaseType {
  func signOut() async {
    print("StubAuthenticationUseCase: signOut")
  }

  func signIn() async -> Result<AuthenticatedUser, AuthenticationUseCaseError> {
    print("StubAuthenticationUseCase: signIn")
    return .success(.hasGroupStub)
  }
}
