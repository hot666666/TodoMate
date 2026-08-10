//
//  UserUseCaseTests.swift
//  TodoMateDomainTests
//
//  Created by agent on 1/9/26.
//

import Foundation
import Testing
@testable import TodoMateDomain

@Suite("Stub User Repository Tests")
struct StubUserRepositoryTests {
  @Test("Default local principal is used consistently for reads and group membership")
  func defaultLocalPrincipal() async throws {
    let repository = StubUserRepository()

    #expect(try await repository.read(userId: User.local.id, useCache: false) == .local)
    #expect(try await repository.read(userId: "firebase-user", useCache: false) == nil)
    #expect(try await repository.readAll(useCache: false) == [.local])
    #expect(try await repository.readAll(groupId: User.local.groupId, useCache: false) == [.local])
    #expect(try await repository.readAll(groupId: "other", useCache: false).isEmpty)
  }
}

// MARK: - UpdateUserUseCase Tests

@Suite("UpdateUserUseCase Tests")
struct UpdateUserUseCaseTests {
  @Test("유효한 이름으로 사용자 업데이트 성공")
  func updateUser_withValidName_succeeds() async throws {
    // Given
    let repository = InMemoryUserRepository()
    let useCase = UpdateUserUseCaseImpl(userRepository: repository)

    let validName = "홍길동"
    let user = User(id: "user1", displayName: validName, groupId: "group1")
    await repository.setUsers([user])

    // When
    try await useCase.execute(user)

    // Then
    let updateCallCount = await repository.updateCallCount
    let lastUpdatedUser = await repository.lastUpdatedUser

    #expect(updateCallCount == 1)
    #expect(lastUpdatedUser?.displayName == validName)
  }

  @Test("빈 이름으로 업데이트 시 에러 발생")
  func updateUser_withEmptyName_throwsError() async {
    // Given
    let repository = InMemoryUserRepository()
    let useCase = UpdateUserUseCaseImpl(userRepository: repository)

    let emptyName = ""
    let user = User(id: "user1", displayName: emptyName, groupId: "group1")

    // When/Then
    do {
      try await useCase.execute(user)
      Issue.record("Expected emptyDisplayName error")
    } catch {
      #expect(error as? UpdateUserError == .emptyDisplayName)
    }
  }

  @Test("공백만 있는 이름으로 업데이트 시 에러 발생")
  func updateUser_withWhitespaceName_throwsError() async {
    // Given
    let repository = InMemoryUserRepository()
    let useCase = UpdateUserUseCaseImpl(userRepository: repository)

    let whitespaceName = "   "
    let user = User(id: "user1", displayName: whitespaceName, groupId: "group1")

    // When/Then
    do {
      try await useCase.execute(user)
      Issue.record("Expected emptyDisplayName error")
    } catch {
      #expect(error as? UpdateUserError == .emptyDisplayName)
    }
  }

  @Test("글자 수 초과 시 에러 발생")
  func updateUser_withTooLongName_throwsError() async {
    // Given
    let repository = InMemoryUserRepository()
    let useCase = UpdateUserUseCaseImpl(userRepository: repository)

    let maxLength = UpdateUserUseCaseImpl.maxDisplayNameLength
    let tooLongName = String(repeating: "가", count: maxLength + 1)
    let user = User(id: "user1", displayName: tooLongName, groupId: "group1")

    // When/Then
    do {
      try await useCase.execute(user)
      Issue.record("Expected displayNameTooLong error")
    } catch let error as UpdateUserError {
      if case let .displayNameTooLong(max) = error {
        #expect(max == maxLength)
      } else {
        Issue.record("Expected displayNameTooLong error")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("최대 글자 수와 동일한 이름은 성공")
  func updateUser_withExactMaxLength_succeeds() async throws {
    // Given
    let repository = InMemoryUserRepository()
    let useCase = UpdateUserUseCaseImpl(userRepository: repository)

    let maxLength = UpdateUserUseCaseImpl.maxDisplayNameLength
    let exactMaxName = String(repeating: "A", count: maxLength)
    let user = User(id: "user1", displayName: exactMaxName, groupId: "group1")
    await repository.setUsers([user])

    // When
    try await useCase.execute(user)

    // Then
    let updateCallCount = await repository.updateCallCount
    #expect(updateCallCount == 1)
  }
}

// MARK: - LeaveGroupUseCase Tests

@Suite("LeaveGroupUseCase Tests")
struct LeaveGroupUseCaseTests {
  @Test("LeaveGroupUseCase는 groupRepository.leaveGroup을 호출함")
  func leaveGroup_callsGroupRepository() async throws {
    // Given
    let userRepository = InMemoryUserRepository()
    let groupRepository = InMemoryGroupRepository()
    let useCase = LeaveGroupUseCaseImpl(
      groupRepository: groupRepository,
      userRepository: userRepository,
    )

    let groupId = "group123"
    let userId = "user1"
    let user = User(id: userId, displayName: "Test", groupId: groupId)
    let group = UserGroup(id: groupId, name: "Test Group", memberIds: [userId])
    await userRepository.setUsers([user])
    await groupRepository.setGroups([group])

    // When
    try await useCase.execute(groupId: groupId, userId: userId)

    // Then
    let leaveGroupCallCount = await groupRepository.leaveGroupCallCount
    let lastLeaveGroupId = await groupRepository.lastLeaveGroupId
    let lastLeaveUserId = await groupRepository.lastLeaveUserId

    #expect(leaveGroupCallCount == 1)
    #expect(lastLeaveGroupId == groupId)
    #expect(lastLeaveUserId == userId)
  }
}
