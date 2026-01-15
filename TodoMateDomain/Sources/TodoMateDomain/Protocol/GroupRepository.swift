//
//  GroupRepository.swift
//  TodoMate
//
//  Created by agent on 1/9/26.
//

import Foundation

public protocol GroupRepository: Sendable {
  func create(_ group: UserGroup) async throws
  func read(groupId: String) async throws -> UserGroup?
  func update(_ group: UserGroup) async throws
  func delete(groupId: String) async throws
  func joinGroup(groupId: String, userId: String, userRepository: UserRepository) async throws
  func leaveGroup(groupId: String, userId: String, userRepository: UserRepository) async throws
}

// MARK: - StubGroupRepository

public final class StubGroupRepository: GroupRepository, Sendable {
  public let groupToReturn: UserGroup?

  public init(groupToReturn: UserGroup? = .stub) {
    self.groupToReturn = groupToReturn
  }

  public func create(_: UserGroup) async throws {}
  public func read(groupId _: String) async throws -> UserGroup? { groupToReturn }
  public func update(_: UserGroup) async throws {}
  public func delete(groupId _: String) async throws {}
  public func joinGroup(groupId _: String, userId _: String, userRepository _: UserRepository)
    async throws {}
  public func leaveGroup(groupId _: String, userId _: String, userRepository _: UserRepository)
    async throws {}
}
