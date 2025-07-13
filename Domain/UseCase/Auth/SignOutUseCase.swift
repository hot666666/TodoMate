//
//  SignOutUseCase.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

protocol SignOutUseCase {
  func run() throws
}

final class SignOutUseCaseImpl: SignOutUseCase {
  private let authService: AuthService

  init(authService: AuthService) {
    self.authService = authService
  }

  func run() throws {
    try authService.signOut()
  }
}

final class StubSignOutUseCase: SignOutUseCase {
  func run() throws {}
}
