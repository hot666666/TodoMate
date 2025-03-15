//
//  AuthenticationUseCase.swift
//  TodoMate
//
//  Created by hs on 3/6/25.
//

enum AuthenticationUseCaseError: Error {
  case signInFailed(String)
}

protocol AuthenticationUseCaseType {
  func signOut() async
  func signIn() async -> Result<AuthenticatedUser, AuthenticationUseCaseError>
}

final class AuthenticationUseCase: AuthenticationUseCaseType {
  private let authService: AuthServiceType
  private let userInfoService: UserInfoServiceType
  private let widgetDataManager: WidgetDataManagerType

  init(authService: AuthServiceType, userInfoService: UserInfoServiceType,
       widgetDataManager: WidgetDataManagerType) {
    self.authService = authService
    self.userInfoService = userInfoService
    self.widgetDataManager = widgetDataManager
  }

  func signOut() async {
    await authService.signOut()
    userInfoService.clearUserInfo()
    await widgetDataManager.removeAll()
  }

  func signIn() async -> Result<AuthenticatedUser, AuthenticationUseCaseError> {
    userInfoService.clearUserInfo()
    do {
      let signedInUser = try await authService.signIn()
      let authenticatedUser = AuthenticatedUser.from(signedInUser)
      try userInfoService.saveUserInfo(authenticatedUser)
      return .success(authenticatedUser)
    } catch {
      return .failure(.signInFailed(error.localizedDescription))
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
