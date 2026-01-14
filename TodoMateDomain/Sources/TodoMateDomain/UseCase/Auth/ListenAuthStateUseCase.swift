//
//  ListenAuthStateUseCase.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

public protocol ListenAuthStateUseCase {
  func run() -> AsyncStream<String?>
}

public final class ListenAuthStateUseCaseImpl: ListenAuthStateUseCase {
  private let authService: AuthService

  public init(authService: AuthService) {
    self.authService = authService
  }

  public func run() -> AsyncStream<String?> {
    authService.listenToAuthStateChanges()
  }
}

public final class StubListenAuthStateUseCase: ListenAuthStateUseCase {
  private let stubAuth = StubAuthService()

  public init() {}

  public func run() -> AsyncStream<String?> {
    stubAuth.listenToAuthStateChanges()
  }
}
