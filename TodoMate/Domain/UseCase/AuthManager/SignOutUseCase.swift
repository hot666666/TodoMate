//
//  SignOutUseCase.swift
//  TodoMate
//
//  Created by hs on 3/22/25.
//

protocol SignOutUseCaseType {
  func execute() async
}

final class SignOutUseCase: SignOutUseCaseType {
  private let authService: AuthServiceType
  private let authenticatedUserCacheService: AuthenticatedUserCacheServiceType
  private let userGroupCacheService: UserGroupCacheServiceType
  private let widgetDataManager: WidgetDataManagerType

  init(authService: AuthServiceType,
       authenticatedUserCacheService: AuthenticatedUserCacheServiceType,
       userGroupCacheService: UserGroupCacheServiceType,
       widgetDataManager: WidgetDataManagerType) {
    self.authService = authService
    self.authenticatedUserCacheService = authenticatedUserCacheService
    self.userGroupCacheService = userGroupCacheService
    self.widgetDataManager = widgetDataManager
  }

  func execute() async {
    await widgetDataManager.removeAll()
    await authService.signOut()
    clearCache()
  }

  private func clearCache() {
    authenticatedUserCacheService.clear()
    userGroupCacheService.clear()
  }
}

class StubSignOutUseCase: SignOutUseCaseType {
  func execute() async {}
}
