//
//  MemoUseCaseIntegrationTests.swift
//  TodoMateFirebaseTests
//
//  Created by agent on 1/8/26.
//

import Foundation
import Testing

@testable import TodoMate

extension FirebaseIntegrationTests {
  /// Firebase 에뮬레이터를 사용한 Memo UseCase 통합 테스트
  @Suite("Memo UseCase Integration Tests", .serialized)
  struct MemoUseCaseIntegrationTests {
    let repository: MemoRepository
    let createUseCase: CreateMemoUseCase
    let readUseCase: ReadGroupMemoUseCase
    let updateUseCase: UpdateMemoUseCase
    let deleteUseCase: DeleteMemoUseCase

    let testUserId = "test-user"

    init() async throws {
      try await FirebaseIntegrationTests.setup()
      let reference = FirestoreReference.shared
      repository = FirestoreMemoRepository(reference: reference)
      createUseCase = CreateMemoUseCaseImpl(repository: repository)
      readUseCase = ReadGroupMemoUseCaseImpl(repository: repository)
      updateUseCase = UpdateMemoUseCaseImpl(repository: repository)
      deleteUseCase = DeleteMemoUseCaseImpl(repository: repository)
    }

    // MARK: - Create

    @Test("Memo 생성 후 조회 가능")
    func createMemo() async throws {
      // Given
      let memo = Memo(owner: testUserId, content: "테스트 메모")

      // When
      try await createUseCase.run(for: testUserId, memo)

      // Then
      let memos = try await readUseCase.run(for: [testUserId], useCache: false)
      let found = memos[testUserId]?.first { $0.id == memo.id }
      #expect(found != nil)
      #expect(found?.content == "테스트 메모")
    }

    // MARK: - Read

    @Test("다중 사용자 Memo 한번에 조회")
    func readMemosFromMultipleUsers() async throws {
      // Given
      let otherUserId = "other-user"
      let myMemo = Memo(owner: testUserId, content: "내 메모")
      let otherMemo = Memo(owner: otherUserId, content: "다른 사람 메모")

      try await createUseCase.run(for: testUserId, myMemo)
      try await createUseCase.run(for: otherUserId, otherMemo)

      // When
      let memos = try await readUseCase.run(for: [testUserId, otherUserId], useCache: false)

      // Then
      #expect(memos[testUserId]?.contains { $0.id == myMemo.id } == true)
      #expect(memos[otherUserId]?.contains { $0.id == otherMemo.id } == true)
    }

    @Test("메모가 없는 사용자도 빈 배열로 반환")
    func readMemosForUserWithNoMemos() async throws {
      // Given
      let emptyUserId = "empty-user"
      let myMemo = Memo(owner: testUserId, content: "내 메모")
      try await createUseCase.run(for: testUserId, myMemo)

      // When
      let memos = try await readUseCase.run(for: [testUserId, emptyUserId], useCache: false)

      // Then
      #expect(memos[testUserId]?.isEmpty == false)
      #expect(memos[emptyUserId]?.isEmpty == true)
    }

    // MARK: - Update

    @Test("Memo 내용 업데이트")
    func updateMemo() async throws {
      // Given
      var memo = Memo(owner: testUserId, content: "원본 내용")
      try await createUseCase.run(for: testUserId, memo)

      // When
      memo = memo.withUpdatedContent("수정된 내용")
      try await updateUseCase.run(for: testUserId, memo)

      // Then
      let memos = try await readUseCase.run(for: [testUserId], useCache: false)
      let updated = memos[testUserId]?.first { $0.id == memo.id }
      #expect(updated?.content == "수정된 내용")
    }

    @Test("다른 사용자의 Memo 수정 시도하면 에러 발생")
    func updateOtherUserMemoFails() async throws {
      // Given
      let otherUserId = "other-user"
      let otherMemo = Memo(owner: otherUserId, content: "다른 사람 메모")
      try await createUseCase.run(for: otherUserId, otherMemo)

      // When & Then
      await #expect(throws: MemoUseCaseError.userNotAuthorized) {
        try await updateUseCase.run(for: testUserId, otherMemo)
      }
    }

    // MARK: - Delete

    @Test("Memo 삭제 후 조회되지 않음")
    func deleteMemo() async throws {
      // Given
      let memo = Memo(owner: testUserId, content: "삭제할 메모")
      try await createUseCase.run(for: testUserId, memo)

      let beforeDelete = try await readUseCase.run(for: [testUserId], useCache: false)
      #expect(beforeDelete[testUserId]?.contains { $0.id == memo.id } == true)

      // When
      try await deleteUseCase.run(for: testUserId, memo)

      // Then
      let afterDelete = try await readUseCase.run(for: [testUserId], useCache: false)
      #expect(afterDelete[testUserId]?.contains { $0.id == memo.id } != true)
    }

    @Test("다른 사용자의 Memo 삭제 시도하면 에러 발생")
    func deleteOtherUserMemoFails() async throws {
      // Given
      let otherUserId = "other-user"
      let otherMemo = Memo(owner: otherUserId, content: "다른 사람 메모")
      try await createUseCase.run(for: otherUserId, otherMemo)

      // When & Then
      await #expect(throws: MemoUseCaseError.userNotAuthorized) {
        try await deleteUseCase.run(for: testUserId, otherMemo)
      }
    }
  }
}
