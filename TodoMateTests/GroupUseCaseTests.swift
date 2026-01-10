//
//  GroupUseCaseTests.swift
//  TodoMateTests
//
//  Created by agent on 1/9/26.
//

import Foundation
import Testing

@testable import TodoMate

// MARK: - Tests

@Suite("GroupUseCase Tests")
struct GroupUseCaseTests {
  @Test("새 그룹 생성")
  func createGroup_savesNewGroup() async throws {
    // Given
    let groupRepository = InMemoryGroupRepository()
    let userRepository = InMemoryUserRepository()

    // CreateGroupUseCaseImpl requires userRepository to update user's groupId
    // So we need to set up a user in userRepository first
    let userId = "user1"
    let user = User(id: userId, displayName: "Test User", groupId: "")
    userRepository.users = [user]

    let useCase = CreateGroupUseCaseImpl(
      groupRepository: groupRepository,
      userRepository: userRepository,
    )

    // When
    let groupName = "New Group"
    let createdGroup = try await useCase.execute(name: groupName, userId: userId)

    // Then
    #expect(groupRepository.groups.count == 1)
    #expect(groupRepository.groups.first?.name == groupName)
    #expect(createdGroup.memberIds.contains(userId))

    // Verify user is updated
    let updatedUser = try await userRepository.read(userId: userId, source: .server)
    #expect(updatedUser?.groupId == createdGroup.id)
  }

  @Test("그룹 조회")
  func readGroup_returnsGroup() async throws {
    // Given
    let repository = InMemoryGroupRepository()
    let useCase = ReadGroupUseCaseImpl(groupRepository: repository)
    let groupId = "group1"
    let group = UserGroup(id: groupId, name: "Test Group", memberIds: ["user1"])
    repository.groups = [group]

    // When
    let result = try await useCase.execute(groupId: groupId)

    // Then
    #expect(result?.name == "Test Group")
  }

  @Test("존재하지 않는 그룹 조회시 nil 반환")
  func readGroup_returnsNilForNonExistentGroup() async throws {
    // Given
    let repository = InMemoryGroupRepository()
    let useCase = ReadGroupUseCaseImpl(groupRepository: repository)

    // When
    let result = try await useCase.execute(groupId: "unknown")

    // Then
    #expect(result == nil)
  }
}
