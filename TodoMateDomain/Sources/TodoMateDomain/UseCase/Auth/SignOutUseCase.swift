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
    do {
      try authService.signOut()
    } catch {
      throw AuthError.signOutFailed(error)
    }
  }
}

public final class StubSignOutUseCase: SignOutUseCase {
  public init() {}
  public func run() throws {}
}
