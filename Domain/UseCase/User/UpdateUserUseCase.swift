//
//  UpdateUserUseCase.swift
//  TodoMate
//
//  Created by hs on 7/12/25.
//

protocol UpdateUserUseCase {
  func execute(_ user: User) async throws
}

final class UpdateUserUseCaseImpl: UpdateUserUseCase {
  private let userRepository: UserRepository

  init(userRepository: UserRepository) {
    self.userRepository = userRepository
  }

  func execute(_ user: User) async throws {
    try await userRepository.update(user)
  }
}

final class StubUpdateUserUseCase: UpdateUserUseCase {
  func execute(_: User) async throws {}
}
