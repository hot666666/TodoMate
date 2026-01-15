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
