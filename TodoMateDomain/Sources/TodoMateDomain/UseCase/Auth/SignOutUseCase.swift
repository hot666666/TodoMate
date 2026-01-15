//
//  SignOutUseCase.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

public protocol SignOutUseCase {
  func run() throws
}

public final class SignOutUseCaseImpl: SignOutUseCase {
  private let authService: AuthService

  public init(authService: AuthService) {
    self.authService = authService
  }

  public func run() throws {
    try authService.signOut()
  }
}

public final class StubSignOutUseCase: SignOutUseCase {
  public init() {}
  public func run() throws {}
}
