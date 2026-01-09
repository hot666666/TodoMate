//
//  UserUseCaseTests.swift
//  TodoMateTests
//
//  Created by agent on 1/9/26.
//

import Foundation
import Testing

@testable import TodoMate

// MARK: - Test Mock Repository

final class InMemoryUserRepository: UserRepository {
  var users: [User] = []
  var updateCallCount = 0
  var lastUpdatedUser: User?

  func create(_ newUser: User) throws -> User {
    users.append(newUser)
    return newUser
  }

  func read(userId: String, source _: DataSource) async throws -> User? {
    users.first { $0.id == userId }
  }

  func readAll(groupId: String, source _: DataSource) async throws -> [User] {
    users.filter { $0.groupId == groupId }
  }

  func readAll(source _: DataSource) async throws -> [User] {
    users
  }

  func update(_ user: User) async throws {
    updateCallCount += 1
    lastUpdatedUser = user
    if let index = users.firstIndex(where: { $0.id == user.id }) {
      users[index] = user
    }
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
    repository.users = [user]

    // When
    try await useCase.execute(user)

    // Then
    #expect(repository.updateCallCount == 1)
    #expect(repository.lastUpdatedUser?.displayName == validName)
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
    repository.users = [user]

    // When
    try await useCase.execute(user)

    // Then
    #expect(repository.updateCallCount == 1)
  }
}

// MARK: - LeaveGroupUseCase Tests

@Suite("LeaveGroupUseCase Tests")
struct LeaveGroupUseCaseTests {
  @Test("그룹 탈퇴 성공 시 groupId가 빈 문자열로 설정됨")
  func leaveGroup_setsGroupIdToEmpty() async throws {
    // Given
    let repository = InMemoryUserRepository()
    let useCase = LeaveGroupUseCaseImpl(userRepository: repository)

    let originalGroupId = "group123"
    let user = User(id: "user1", displayName: "Test", groupId: originalGroupId)
    repository.users = [user]

    // When
    try await useCase.execute(for: user)

    // Then
    #expect(repository.updateCallCount == 1)
    #expect(repository.lastUpdatedUser?.groupId == "")
    #expect(repository.lastUpdatedUser?.id == user.id)
  }

  @Test("그룹 탈퇴 시 updatedAt이 갱신됨")
  func leaveGroup_updatesTimestamp() async throws {
    // Given
    let repository = InMemoryUserRepository()
    let useCase = LeaveGroupUseCaseImpl(userRepository: repository)

    let oldDate = Date.distantPast
    let user = User(
      id: "user1",
      displayName: "Test",
      groupId: "group123",
      createdAt: oldDate,
      updatedAt: oldDate,
    )
    repository.users = [user]

    // When
    try await useCase.execute(for: user)

    // Then
    #expect(repository.lastUpdatedUser?.updatedAt != oldDate)
  }
}
