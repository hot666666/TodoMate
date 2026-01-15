//
//  JoinGroupUseCase.swift
//  TodoMate
//
//  Created by agent on 1/9/26.
//

public protocol JoinGroupUseCase {
  func execute(groupId: String, userId: String) async throws
}

public struct JoinGroupUseCaseImpl: JoinGroupUseCase {
  private let groupRepository: GroupRepository
  private let userRepository: UserRepository

  public init(groupRepository: GroupRepository, userRepository: UserRepository) {
    self.groupRepository = groupRepository
    self.userRepository = userRepository
  }

  public func execute(groupId: String, userId: String) async throws {
    // Use transaction-based join for concurrency safety
    try await groupRepository.joinGroup(
      groupId: groupId,
      userId: userId,
      userRepository: userRepository,
    )
  }
}

public enum JoinGroupError: Error {
  case groupNotFound
  case alreadyMember
}
