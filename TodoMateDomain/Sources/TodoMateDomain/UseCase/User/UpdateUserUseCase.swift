//
//  UpdateUserUseCase.swift
//  TodoMate
//
//  Created by hs on 7/12/25.
//

protocol UpdateUserUseCase {
  func execute(_ user: User) async throws
}

enum UpdateUserError: Error, Equatable {
  case emptyDisplayName
  case displayNameTooLong(maxLength: Int)
}

final class UpdateUserUseCaseImpl: UpdateUserUseCase {
  private let userRepository: UserRepository

  static let maxDisplayNameLength = 20

  init(userRepository: UserRepository) {
    self.userRepository = userRepository
  }

  func execute(_ user: User) async throws {
    // Validation
    guard !user.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw UpdateUserError.emptyDisplayName
    }

    guard user.displayName.count <= Self.maxDisplayNameLength else {
      throw UpdateUserError.displayNameTooLong(maxLength: Self.maxDisplayNameLength)
    }

    try await userRepository.update(user)
  }
}

final class StubUpdateUserUseCase: UpdateUserUseCase {
  func execute(_: User) async throws {}
}
