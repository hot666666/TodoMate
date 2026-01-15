//
//  MemoRepositoryIntegrationTests.swift
//  TodoMateDataTests
//
//  Created by agent on 1/8/26.
//

import Foundation
import Testing
import TodoMateDomain

@testable import TodoMateData

extension FirestoreIntegrationTests {
  /// Firebase 에뮬레이터를 사용한 MemoRepository 통합 테스트
  /// .serialized: 병렬 실행 시 resetAllCollections()가 다른 테스트 데이터를 삭제할 수 있어 직렬 실행 필수
  @Suite("Memo Repository Integration Tests", .serialized)
  struct MemoRepositoryIntegrationTests {
    let repository: MemoRepository
    let testUserId = "test-user"

    init() async throws {
      try await FirestoreIntegrationTests.setup()
      let reference = FirestoreReference.shared!
      repository = FirestoreMemoRepository(reference: reference)
    }

    // MARK: - Create & Read

    @Test("Memo 생성 및 조회 확인")
    func createAndReadMemo() async throws {
      // Given
      let memo = Memo(owner: testUserId, content: "Repository 테스트 메모")

      // When
      try await repository.create(memo)

      // Then
      let results = try await repository.readAllByUserId(testUserId, useCache: false)

      let found = results.first { $0.id == memo.id }
      #expect(found != nil)
      #expect(found?.content == "Repository 테스트 메모")
      #expect(found?.owner == testUserId)
    }

    // MARK: - Update

    @Test("Memo 내용 수정")
    func updateMemo() async throws {
      // Given
      var memo = Memo(owner: testUserId, content: "수정 전")
      try await repository.create(memo)

      // When
      memo.content = "수정 후"
      try await repository.update(memo)

      // Then
      let results = try await repository.readAllByUserId(testUserId, useCache: false)
      let updated = results.first { $0.id == memo.id }

      #expect(updated?.content == "수정 후")
    }

    // MARK: - Delete

    @Test("Memo 삭제")
    func deleteMemo() async throws {
      // Given
      let memo = Memo(owner: testUserId, content: "삭제될 메모")
      try await repository.create(memo)

      // When
      try await repository.delete(memo)

      // Then
      let results = try await repository.readAllByUserId(testUserId, useCache: false)
      #expect(!results.contains { $0.id == memo.id })
    }

    // MARK: - Multiple Memos

    @Test("다중 메모 조회")
    func readMultipleMemos() async throws {
      // Given
      let memo1 = Memo(owner: testUserId, content: "첫 번째 메모")
      let memo2 = Memo(owner: testUserId, content: "두 번째 메모")
      let memo3 = Memo(owner: testUserId, content: "세 번째 메모")

      try await repository.create(memo1)
      try await repository.create(memo2)
      try await repository.create(memo3)

      // When
      let results = try await repository.readAllByUserId(testUserId, useCache: false)

      // Then
      #expect(results.count >= 3)
      let ids = Set(results.map(\.id))
      #expect(ids.contains(memo1.id))
      #expect(ids.contains(memo2.id))
      #expect(ids.contains(memo3.id))
    }

    // MARK: - Read by Multiple Users

    @Test("다중 사용자 메모 조회")
    func readMemosByMultipleUsers() async throws {
      // Given
      let otherUserId = "other-user"
      let memo1 = Memo(owner: testUserId, content: "내 메모")
      let memo2 = Memo(owner: otherUserId, content: "다른 사람 메모")

      try await repository.create(memo1)
      try await repository.create(memo2)

      // When
      let results = try await repository.readAllByUserIds(
        [testUserId, otherUserId], useCache: false,
      )

      // Then
      let ids = Set(results.map(\.id))
      #expect(ids.contains(memo1.id))
      #expect(ids.contains(memo2.id))
    }
  }
}
