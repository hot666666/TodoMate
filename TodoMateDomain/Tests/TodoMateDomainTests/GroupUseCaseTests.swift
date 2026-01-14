//
//  GroupUseCaseTests.swift
//  TodoMateDomainTests
//
//  Created by agent on 1/9/26.
//

import Foundation
import Testing

@testable import TodoMateDomain

// MARK: - Tests

@Suite("GroupUseCase Tests")
struct GroupUseCaseTests {
  @Test("새 그룹 생성")
  func createGroup_savesNewGroup() async throws {
    // Given
    let groupRepository = InMemoryGroupRepository()
    let userRepository = InMemoryUserRepository()

    let userId = "user1"
    let user = User(id: userId, displayName: "Test User", groupId: "")
    await userRepository.setUsers([user])

    let useCase = CreateGroupUseCaseImpl(
      groupRepository: groupRepository,
      userRepository: userRepository,
    )

    // When
    let groupName = "New Group"
    let createdGroup = try await useCase.execute(name: groupName, userId: userId)

    // Then
    let groupCount = await groupRepository.groups.count
    let firstGroup = await groupRepository.groups.first

    #expect(groupCount == 1)
    #expect(firstGroup?.name == groupName)
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
    await repository.setGroups([group])

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
