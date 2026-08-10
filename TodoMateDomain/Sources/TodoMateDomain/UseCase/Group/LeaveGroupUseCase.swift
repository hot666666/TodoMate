//
//  LeaveGroupUseCase.swift
//  TodoMate
//
//  Created by agent on 1/9/26.
//

public protocol LeaveGroupUseCase: Sendable {
  func execute(groupId: String, userId: String) async throws
}

public struct LeaveGroupUseCaseImpl: LeaveGroupUseCase {
  private let groupRepository: GroupRepository
  private let userRepository: UserRepository

  public init(groupRepository: GroupRepository, userRepository: UserRepository) {
    self.groupRepository = groupRepository
    self.userRepository = userRepository
  }

  public func execute(groupId: String, userId: String) async throws {
    // Use transaction-based leave for concurrency safety
    // Will delete group if last member leaves
    try await groupRepository.leaveGroup(
      groupId: groupId,
      userId: userId,
      userRepository: userRepository,
    )
  }
}
