//
//  SignInUseCase.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

protocol SignInUseCase {
  func run() async throws
}

final class SignInUseCaseImpl: SignInUseCase {
  private let authService: AuthService

  init(authService: AuthService) {
    self.authService = authService
  }

  func run() async throws {
    try await authService.signIn()
  }
}

final class StubSignInUseCase: SignInUseCase {
  func run() async throws {}
}
