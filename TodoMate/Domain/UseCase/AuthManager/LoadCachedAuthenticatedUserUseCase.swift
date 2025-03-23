//
//  LoadCachedAuthenticatedUserUseCase.swift
//  TodoMate
//
//  Created by hs on 3/6/25.
//

protocol LoadCachedAuthenticatedUserUseCaseType {
  func execute() -> AuthenticatedUser?
}

final class LoadCachedAuthenticatedUserUseCase: LoadCachedAuthenticatedUserUseCaseType {
  private let authenticatedUserCacheService: AuthenticatedUserCacheServiceType

  init(userInfoService: AuthenticatedUserCacheServiceType) {
    authenticatedUserCacheService = userInfoService
  }

  func execute() -> AuthenticatedUser? {
    try? authenticatedUserCacheService.load()
  }
}

class StubLoadCachedAuthenticatedUserUseCase: LoadCachedAuthenticatedUserUseCaseType {
  func execute() -> AuthenticatedUser? {
    .stub
  }
}
