//
//  JoinGroupUseCase.swift
//  TodoMate
//
//  Created by agent on 1/9/26.
//

protocol JoinGroupUseCase {
  func execute(groupId: String, userId: String) async throws
}

struct JoinGroupUseCaseImpl: JoinGroupUseCase {
  private let groupRepository: GroupRepository
  private let userRepository: UserRepository

  init(groupRepository: GroupRepository, userRepository: UserRepository) {
    self.groupRepository = groupRepository
    self.userRepository = userRepository
  }

  func execute(groupId: String, userId: String) async throws {
    // Use transaction-based join for concurrency safety
    try await groupRepository.joinGroup(
      groupId: groupId,
      userId: userId,
      userRepository: userRepository,
    )
  }
}

enum JoinGroupError: Error {
  case groupNotFound
  case alreadyMember
}
