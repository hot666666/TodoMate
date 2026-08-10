//
//  ReadGroupUseCase.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import Foundation

public protocol ReadGroupUseCase: Sendable {
  func execute(groupId: String) async throws -> UserGroup?
}

public struct ReadGroupUseCaseImpl: ReadGroupUseCase {
  private let groupRepository: GroupRepository

  public init(groupRepository: GroupRepository) {
    self.groupRepository = groupRepository
  }

  public func execute(groupId: String) async throws -> UserGroup? {
    try await groupRepository.read(groupId: groupId)
  }
}
