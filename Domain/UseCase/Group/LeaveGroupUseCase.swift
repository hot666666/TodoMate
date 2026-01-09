//
//  LeaveGroupUseCase.swift
//  TodoMate
//
//  Created by agent on 1/9/26.
//

protocol LeaveGroupUseCase {
  func execute(groupId: String, userId: String) async throws
}

struct LeaveGroupUseCaseImpl: LeaveGroupUseCase {
  private let groupRepository: GroupRepository
  private let userRepository: UserRepository

  init(groupRepository: GroupRepository, userRepository: UserRepository) {
    self.groupRepository = groupRepository
    self.userRepository = userRepository
  }

  func execute(groupId: String, userId: String) async throws {
    // Use transaction-based leave for concurrency safety
    // Will delete group if last member leaves
    try await groupRepository.leaveGroup(
      groupId: groupId,
      userId: userId,
      userRepository: userRepository,
    )
  }
}

enum LeaveGroupError: Error {
  case groupNotFound
  case notMember
}
