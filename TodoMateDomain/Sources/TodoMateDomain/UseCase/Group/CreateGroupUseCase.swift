//
//  CreateGroupUseCase.swift
//  TodoMate
//
//  Created by agent on 1/9/26.
//

public protocol CreateGroupUseCase {
  func execute(name: String, userId: String) async throws -> UserGroup
}

public struct CreateGroupUseCaseImpl: CreateGroupUseCase {
  private let groupRepository: GroupRepository
  private let userRepository: UserRepository

  public init(groupRepository: GroupRepository, userRepository: UserRepository) {
    self.groupRepository = groupRepository
    self.userRepository = userRepository
  }

  public func execute(name: String, userId: String) async throws -> UserGroup {
    let group = UserGroup(name: name, memberIds: [userId])
    try await groupRepository.create(group)

    // Update user's groupId
    guard var user = try await userRepository.read(userId: userId, source: .server) else {
      throw CreateGroupError.userNotFound
    }
    user.groupId = group.id
    user.updatedAt = .now
    try await userRepository.update(user)

    return group
  }
}

public enum CreateGroupError: Error {
  case userNotFound
}
