//
//  LocalMemoUseCaseTests.swift
//  TodoMateTests
//
//  Created by agent on 1/13/26.
//

import Foundation
import Testing

@testable import TodoMate

@Suite("Local Memo UseCases Tests")
struct LocalMemoUseCaseTests {
  // MARK: - Mock Repository

  final class MockMemoRepository: MemoRepository {
    var memos: [Memo] = []
    var createCallCount = 0
    var updateCallCount = 0
    var deleteCallCount = 0
    var readCallCount = 0

    func create(_ memo: Memo) async throws {
      createCallCount += 1
      memos.append(memo)
    }

    func update(_ memo: Memo) async throws {
      updateCallCount += 1
      if let index = memos.firstIndex(where: { $0.id == memo.id }) {
        memos[index] = memo
      }
    }

    func delete(_ memo: Memo) async throws {
      deleteCallCount += 1
      memos.removeAll { $0.id == memo.id }
    }

    func readAllByUserId(_: String, useCache _: Bool) async throws -> [Memo] {
      readCallCount += 1
      return memos // Start simple, return all for now or filter if needed
    }

    func readAllByUserIds(_: [String], useCache _: Bool) async throws -> [Memo] {
      readCallCount += 1
      return memos
    }

    // Add stub implementations for other protocol methods if any
    func readAll(groupId _: String, source _: DataSource) async throws -> [Memo] { [] }
    func read(memoId _: String) async throws -> Memo? { nil }
  }

  // MARK: - Tests

  @Test("Create Local Memo")
  func createMemo() async throws {
    let repository = MockMemoRepository()
    let useCase = CreateLocalMemoUseCaseImpl(repository: repository)
    let memo = Memo(owner: "user1", content: "Test Memo")

    try await useCase.run(memo)

    #expect(repository.createCallCount == 1)
    #expect(repository.memos.count == 1)
    #expect(repository.memos.first?.id == memo.id)
  }

  @Test("Read Local Memos")
  func readMemos() async throws {
    let repository = MockMemoRepository()
    let memo1 = Memo(owner: "user1", content: "Memo 1")
    repository.memos = [memo1]

    let useCase = ReadLocalMemoUseCaseImpl(repository: repository)

    let result = try await useCase.run()

    #expect(repository.readCallCount == 1)
    #expect(result.count == 1)
    #expect(result.first?.id == memo1.id)
  }

  @Test("Update Local Memo")
  func updateMemo() async throws {
    let repository = MockMemoRepository()
    let memo = Memo(owner: "user1", content: "Original")
    repository.memos = [memo]

    let useCase = UpdateLocalMemoUseCaseImpl(repository: repository)
    let updatedMemo = memo.withUpdatedContent("Updated")

    try await useCase.run(updatedMemo)

    #expect(repository.updateCallCount == 1)
    #expect(repository.memos.first?.content == "Updated")
  }

  @Test("Delete Local Memo")
  func deleteMemo() async throws {
    let repository = MockMemoRepository()
    let memo = Memo(owner: "user1", content: "To Delete")
    repository.memos = [memo]

    let useCase = DeleteLocalMemoUseCaseImpl(repository: repository)

    try await useCase.run(memo)

    #expect(repository.deleteCallCount == 1)
    #expect(repository.memos.isEmpty)
  }
}
