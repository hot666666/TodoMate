//
//  ReadGroupUseCase.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import Foundation

protocol ReadGroupUseCase {
  func execute(groupId: String) async throws -> UserGroup?
}

struct ReadGroupUseCaseImpl: ReadGroupUseCase {
  private let groupRepository: GroupRepository

  init(groupRepository: GroupRepository) {
    self.groupRepository = groupRepository
  }

  func execute(groupId: String) async throws -> UserGroup? {
    try await groupRepository.read(groupId: groupId)
  }
}
