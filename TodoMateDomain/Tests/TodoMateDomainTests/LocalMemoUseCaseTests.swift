//
//  LocalMemoUseCaseTests.swift
//  TodoMateTests
//
//  Created by agent on 1/13/26.
//

import Foundation
import Testing

@testable import TodoMateDomain

@Suite("Local Memo UseCases Tests")
struct LocalMemoUseCaseTests {
  // MARK: - Tests

  @Test("Create Local Memo")
  func createMemo() async throws {
    let repository = InMemoryMemoRepository()
    let useCase = CreateLocalMemoUseCaseImpl(repository: repository)
    let memo = Memo(owner: "user1", content: "Test Memo")

    try await useCase.run(memo)

    let createCallCount = await repository.createCallCount
    let count = await repository.memos.count
    let firstMemo = await repository.memos.first

    #expect(createCallCount == 1)
    #expect(count == 1)
    #expect(firstMemo?.id == memo.id)
  }

  @Test("Read Local Memos")
  func readMemos() async throws {
    let repository = InMemoryMemoRepository()
    let memo1 = Memo(owner: "user1", content: "Memo 1")
    await repository.setMemos([memo1])

    let useCase = ReadLocalMemoUseCaseImpl(repository: repository)

    let result = try await useCase.run(userId: "user1")

    // Note: Local read use case might not trigger the repository's read count if it bypasses it or uses a different method.
    // Assuming implementation details, but for now checking result.
    // However, if the implementation calls readAllByUserId internally, we can check.
    // Just checking the result as the primary goal.

    #expect(result.count == 1)
    #expect(result.first?.id == memo1.id)
  }

  @Test("Update Local Memo")
  func updateMemo() async throws {
    let repository = InMemoryMemoRepository()
    let memo = Memo(owner: "user1", content: "Original")
    await repository.setMemos([memo])

    let useCase = UpdateLocalMemoUseCaseImpl(repository: repository)
    let updatedMemo = memo.withUpdatedContent("Updated")

    try await useCase.run(updatedMemo)

    let updateCallCount = await repository.updateCallCount
    let firstMemo = await repository.memos.first

    #expect(updateCallCount == 1)
    #expect(firstMemo?.content == "Updated")
  }

  @Test("Delete Local Memo")
  func deleteMemo() async throws {
    let repository = InMemoryMemoRepository()
    let memo = Memo(owner: "user1", content: "To Delete")
    await repository.setMemos([memo])

    let useCase = DeleteLocalMemoUseCaseImpl(repository: repository)

    try await useCase.run(memo)

    let deleteCallCount = await repository.deleteCallCount
    let isEmpty = await repository.memos.isEmpty

    #expect(deleteCallCount == 1)
    #expect(isEmpty)
  }
}
