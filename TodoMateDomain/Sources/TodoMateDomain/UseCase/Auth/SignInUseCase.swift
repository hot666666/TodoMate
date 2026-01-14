//
//  SignInUseCase.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

public protocol SignInUseCase {
  func run() async throws
}

public final class SignInUseCaseImpl: SignInUseCase {
  private let authService: AuthService

  public init(authService: AuthService) {
    self.authService = authService
  }

  public func run() async throws {
    try await authService.signIn()
  }
}

public final class StubSignInUseCase: SignInUseCase {
  public init() {}
  public func run() async throws {}
}
