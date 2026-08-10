//
//  UpdateUserUseCase.swift
//  TodoMate
//
//  Created by hs on 7/12/25.
//

import Foundation

public protocol UpdateUserUseCase: Sendable {
  func execute(_ user: User) async throws
}

public final class UpdateUserUseCaseImpl: UpdateUserUseCase {
  private let userRepository: UserRepository

  public static let maxDisplayNameLength = 20

  public init(userRepository: UserRepository) {
    self.userRepository = userRepository
  }

  public func execute(_ user: User) async throws {
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

public final class StubUpdateUserUseCase: UpdateUserUseCase {
  public init() {}
  public func execute(_: User) async throws {}
}
