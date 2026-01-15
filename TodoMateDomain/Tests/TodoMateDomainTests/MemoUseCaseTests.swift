//
//  MemoUseCaseTests.swift
//  TodoMateDomainTests
//
//  Created by agent on 1/8/26.
//

import Foundation
import Testing

@testable import TodoMateDomain

// MARK: - CreateMemoUseCase Tests

@Suite("CreateMemoUseCase Tests")
struct CreateMemoUseCaseTests {
  @Test("새 메모 생성 성공")
  func createMemo_savesNewMemo() async throws {
    // Given
    let repository = InMemoryMemoRepository()
    let useCase = CreateMemoUseCaseImpl(repository: repository)
    let userId = "user1"
    let memo = Memo(owner: userId, content: "Test Content")

    // When
    try await useCase.run(for: userId, memo)

    // Then
    let count = await repository.memos.count
    let firstMemo = await repository.memos.first

    #expect(count == 1)
    #expect(firstMemo?.content == "Test Content")
    #expect(firstMemo?.owner == userId)
  }

  @Test("권한 없는 사용자가 메모 생성 시 에러")
  func createMemo_throwsForUnauthorizedUser() async {
    // Given
    let repository = InMemoryMemoRepository()
    let useCase = CreateMemoUseCaseImpl(repository: repository)
    let ownerId = "user1"
    let differentUserId = "user2"
    let memo = Memo(owner: ownerId, content: "Test")

    // When/Then
    do {
      try await useCase.run(for: differentUserId, memo)
      Issue.record("Expected userNotAuthorized error")
    } catch {
      #expect(error as? MemoUseCaseError == .userNotAuthorized)
    }
  }
}

// MARK: - ReadGroupMemoUseCase Tests

@Suite("ReadGroupMemoUseCase Tests")
struct ReadGroupMemoUseCaseTests {
  @Test("여러 사용자의 메모 조회")
  func readGroupMemo_returnsMultipleMemos() async throws {
    // Given
    let repository = InMemoryMemoRepository()
    let useCase = ReadGroupMemoUseCaseImpl(repository: repository)

    let user1 = "user1"
    let user2 = "user2"
    let memo1 = Memo(owner: user1, content: "User1 Memo 1")
    let memo2 = Memo(owner: user1, content: "User1 Memo 2")
    let memo3 = Memo(owner: user2, content: "User2 Memo")
    await repository.setMemos([memo1, memo2, memo3])

    // When
    let result = try await useCase.run(for: [user1, user2], useCache: true)

    // Then
    #expect(result[user1]?.count == 2)
    #expect(result[user2]?.count == 1)
  }

  @Test("메모가 없는 사용자는 빈 배열 반환")
  func readGroupMemo_returnsEmptyArrayForUserWithNoMemos() async throws {
    // Given
    let repository = InMemoryMemoRepository()
    let useCase = ReadGroupMemoUseCaseImpl(repository: repository)

    let user1 = "user1"
    let userWithNoMemos = "user_empty"
    await repository.setMemos([Memo(owner: user1, content: "Content")])

    // When
    let result = try await useCase.run(for: [user1, userWithNoMemos], useCache: true)

    // Then
    #expect(result[user1]?.count == 1)
    #expect(result[userWithNoMemos]?.isEmpty == true)
  }
}

// MARK: - UpdateMemoUseCase Tests

@Suite("UpdateMemoUseCase Tests")
struct UpdateMemoUseCaseTests {
  @Test("메모 내용 업데이트 성공")
  func updateMemo_updatesExistingMemo() async throws {
    // Given
    let repository = InMemoryMemoRepository()
    let useCase = UpdateMemoUseCaseImpl(repository: repository)

    let userId = "user1"
    let originalContent = "Original Content"
    let updatedContent = "Updated Content"
    let memo = Memo(owner: userId, content: originalContent)
    await repository.setMemos([memo])

    // When
    let updatedMemo = memo.withUpdatedContent(updatedContent)
    try await useCase.run(for: userId, updatedMemo)

    // Then
    let firstMemo = await repository.memos.first
    #expect(firstMemo?.content == updatedContent)
  }
}

// MARK: - DeleteMemoUseCase Tests

@Suite("DeleteMemoUseCase Tests")
struct DeleteMemoUseCaseTests {
  @Test("메모 삭제 성공")
  func deleteMemo_removesMemo() async throws {
    // Given
    let repository = InMemoryMemoRepository()
    let useCase = DeleteMemoUseCaseImpl(repository: repository)

    let userId = "user1"
    let memo = Memo(owner: userId, content: "To be deleted")
    await repository.setMemos([memo])

    // When
    try await useCase.run(for: userId, memo)

    // Then
    let isEmpty = await repository.memos.isEmpty
    #expect(isEmpty)
  }

  @Test("권한 없는 사용자가 메모 삭제 시 에러")
  func deleteMemo_throwsForUnauthorizedUser() async {
    // Given
    let repository = InMemoryMemoRepository()
    let useCase = DeleteMemoUseCaseImpl(repository: repository)

    let ownerId = "user1"
    let differentUserId = "user2"
    let memo = Memo(owner: ownerId, content: "Test")
    await repository.setMemos([memo])

    // When/Then
    do {
      try await useCase.run(for: differentUserId, memo)
      Issue.record("Expected userNotAuthorized error")
    } catch {
      #expect(error as? MemoUseCaseError == .userNotAuthorized)
    }
  }
}
