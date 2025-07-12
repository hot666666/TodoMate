//
//  ListenAuthStateUseCase.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

protocol ListenAuthStateUseCase {
  func run() -> AsyncStream<String?>
}

final class ListenAuthStateUseCaseImpl: ListenAuthStateUseCase {
  private let authService: AuthService

  init(authService: AuthService) {
    self.authService = authService
  }

  func run() -> AsyncStream<String?> {
    authService.listenToAuthStateChanges()
  }
}

final class StubListenAuthStateUseCase: ListenAuthStateUseCase {
  private let stubAuth = StubAuthService()

  func run() -> AsyncStream<String?> {
    stubAuth.listenToAuthStateChanges()
  }
}
