//
//  MemoUseCaseTests.swift
//  TodoMateTests
//
//  Created by agent on 1/8/26.
//

import Testing

@testable import TodoMate

// MARK: - Test Mock Repository

final class InMemoryMemoRepository: MemoRepository {
  var memos: [Memo] = []

  func create(_ memo: Memo) async throws {
    memos.append(memo)
  }

  func update(_ memo: Memo) async throws {
    if let index = memos.firstIndex(where: { $0.id == memo.id }) {
      memos[index] = memo
    }
  }

  func delete(_ memo: Memo) async throws {
    memos.removeAll { $0.id == memo.id }
  }

  func readAllByUserId(_ userId: String, useCache _: Bool) async throws -> [Memo] {
    memos.filter { $0.owner == userId }
  }

  func readAllByUserIds(_ userIds: [String], useCache _: Bool) async throws -> [Memo] {
    memos.filter { userIds.contains($0.owner) }
  }
}

// MARK: - CreateMemoUseCase Tests

@Suite("CreateMemoUseCase Tests")
struct CreateMemoUseCaseTests {
  let repository = InMemoryMemoRepository()

  @Test("새 메모 생성 및 저장")
  func createMemo_savesNewMemo() async throws {
    // Given
    let useCase = CreateMemoUseCaseImpl(repository: repository)
    let userId = "user1"
    let memo = Memo(owner: userId, content: "Test Content")

    // When
    try await useCase.run(for: userId, memo)

    // Then
    #expect(repository.memos.count == 1)
    #expect(repository.memos.first?.content == "Test Content")
    #expect(repository.memos.first?.owner == userId)
  }

  @Test("다른 사용자의 메모 생성 시도 시 에러")
  func createMemo_throwsForUnauthorizedUser() async {
    // Given
    let useCase = CreateMemoUseCaseImpl(repository: repository)
    let ownerId = "user1"
    let differentUserId = "user2"
    let memo = Memo(owner: ownerId, content: "Test")

    // When/Then
    await #expect(throws: MemoUseCaseError.userNotAuthorized) {
      try await useCase.run(for: differentUserId, memo)
    }
  }
}

// MARK: - ReadGroupMemoUseCase Tests

@Suite("ReadGroupMemoUseCase Tests")
struct ReadGroupMemoUseCaseTests {
  @Test("그룹 멤버 메모 다중 조회")
  func readGroupMemo_returnsMultipleMemos() async throws {
    // Given
    let repository = InMemoryMemoRepository()
    let useCase = ReadGroupMemoUseCaseImpl(repository: repository)

    let user1 = "user1"
    let user2 = "user2"
    let memo1 = Memo(owner: user1, content: "User1 Memo 1")
    let memo2 = Memo(owner: user1, content: "User1 Memo 2")
    let memo3 = Memo(owner: user2, content: "User2 Memo")
    repository.memos = [memo1, memo2, memo3]

    // When
    let result = try await useCase.run(for: [user1, user2], useCache: true)

    // Then
    #expect(result[user1]?.count == 2)
    #expect(result[user2]?.count == 1)
  }

  @Test("메모가 없는 유저도 빈 배열로 반환")
  func readGroupMemo_returnsEmptyArrayForUserWithNoMemos() async throws {
    // Given
    let repository = InMemoryMemoRepository()
    let useCase = ReadGroupMemoUseCaseImpl(repository: repository)

    let user1 = "user1"
    let userWithNoMemos = "user_empty"
    repository.memos = [Memo(owner: user1, content: "Content")]

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
  @Test("기존 메모 업데이트")
  func updateMemo_updatesExistingMemo() async throws {
    // Given
    let repository = InMemoryMemoRepository()
    let useCase = UpdateMemoUseCaseImpl(repository: repository)

    let userId = "user1"
    let originalContent = "Original Content"
    let updatedContent = "Updated Content"
    let memo = Memo(owner: userId, content: originalContent)
    repository.memos = [memo]

    // When
    let updatedMemo = memo.withUpdatedContent(updatedContent)
    try await useCase.run(for: userId, updatedMemo)

    // Then
    #expect(repository.memos.first?.content == updatedContent)
  }
}

// MARK: - DeleteMemoUseCase Tests

@Suite("DeleteMemoUseCase Tests")
struct DeleteMemoUseCaseTests {
  @Test("메모 삭제")
  func deleteMemo_removesMemo() async throws {
    // Given
    let repository = InMemoryMemoRepository()
    let useCase = DeleteMemoUseCaseImpl(repository: repository)

    let userId = "user1"
    let memo = Memo(owner: userId, content: "To be deleted")
    repository.memos = [memo]

    // When
    try await useCase.run(for: userId, memo)

    // Then
    #expect(repository.memos.isEmpty)
  }

  @Test("다른 사용자의 메모 삭제 시도 시 에러")
  func deleteMemo_throwsForUnauthorizedUser() async {
    // Given
    let repository = InMemoryMemoRepository()
    let useCase = DeleteMemoUseCaseImpl(repository: repository)

    let ownerId = "user1"
    let differentUserId = "user2"
    let memo = Memo(owner: ownerId, content: "Test")
    repository.memos = [memo]

    // When/Then
    do {
      try await useCase.run(for: differentUserId, memo)
      Issue.record("Expected error to be thrown")
    } catch {
      #expect(error as? MemoUseCaseError == .userNotAuthorized)
    }
  }
}
