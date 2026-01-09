//
//  LeaveGroupUseCase.swift
//  TodoMate
//
//  Created by agent on 1/9/26.
//

import Foundation

protocol LeaveGroupUseCase {
  func execute(for user: User) async throws
}

final class LeaveGroupUseCaseImpl: LeaveGroupUseCase {
  private let userRepository: UserRepository

  init(userRepository: UserRepository) {
    self.userRepository = userRepository
  }

  func execute(for user: User) async throws {
    var updatedUser = user
    updatedUser.groupId = ""
    updatedUser.updatedAt = Date()
    try await userRepository.update(updatedUser)
  }
}

final class StubLeaveGroupUseCase: LeaveGroupUseCase {
  func execute(for _: User) async throws {}
}
