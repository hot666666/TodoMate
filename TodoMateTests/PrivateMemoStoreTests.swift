//
//  PrivateMemoStoreTests.swift
//  TodoMateTests
//
//  Created by agent on 1/14/26.
//

import Foundation
import Testing
import TodoMateDomain

@testable import TodoMate

@Suite("PrivateMemoStore Unit Tests")
@MainActor
struct PrivateMemoStoreTests {
  // MARK: - Mock UseCases

  final class MockCreateUseCase: CreateLocalMemoUseCase {
    var runHandler: ((Memo) -> Void)?
    func run(_ memo: Memo) async throws { runHandler?(memo) }
  }

  final class MockReadUseCase: ReadLocalMemoUseCase {
    var memos: [Memo] = []
    func run(userId _: String) async throws -> [Memo] {
      memos
    }
  }

  final class MockUpdateUseCase: UpdateLocalMemoUseCase {
    var runHandler: ((Memo) -> Void)?
    func run(_ memo: Memo) async throws { runHandler?(memo) }
  }

  final class MockDeleteUseCase: DeleteLocalMemoUseCase {
    var runHandler: ((Memo) -> Void)?
    func run(_ memo: Memo) async throws { runHandler?(memo) }
  }

  // MARK: - Tests

  @Test("Load returns memos sorted by createdAt descending")
  func load_returnsSortedMemos() async {
    // Given
    let createUC = MockCreateUseCase()
    let readUC = MockReadUseCase()
    let updateUC = MockUpdateUseCase()
    let deleteUC = MockDeleteUseCase()

    let store = PrivateMemoStore(
      createUseCase: createUC,
      readUseCase: readUC,
      updateUseCase: updateUC,
      deleteUseCase: deleteUC,
    )

    let now = Date()
    let oneHourAgo = now.addingTimeInterval(-3600)
    let twoHoursAgo = now.addingTimeInterval(-7200)

    let memo1 = Memo(owner: "user", content: "Oldest", date: twoHoursAgo)
    let memo2 = Memo(owner: "user", content: "Middle", date: oneHourAgo)
    let memo3 = Memo(owner: "user", content: "Newest", date: now)

    readUC.memos = [memo1, memo2, memo3]

    // When
    await store.load()

    // Then
    #expect(store.memos.count == 3)
    #expect(store.memos[0].content == "Newest")
    #expect(store.memos[1].content == "Middle")
    #expect(store.memos[2].content == "Oldest")
  }

  @Test("Add memo refreshes list")
  func add_refreshesList() async {
    // Given
    let createUC = MockCreateUseCase()
    let readUC = MockReadUseCase()
    let updateUC = MockUpdateUseCase()
    let deleteUC = MockDeleteUseCase()

    let store = PrivateMemoStore(
      createUseCase: createUC,
      readUseCase: readUC,
      updateUseCase: updateUC,
      deleteUseCase: deleteUC,
    )

    var created = false
    createUC.runHandler = { _ in created = true }

    let memo = Memo(owner: "user", content: "New Memo")
    readUC.memos = [memo]

    // When
    store.add(content: "New Memo")

    // Wait for async task
    try? await Task.sleep(for: .milliseconds(100))

    // Then
    #expect(created)
    #expect(store.memos.count == 1)
    #expect(store.memos.first?.content == "New Memo")
  }

  @Test("Update memo refreshes list")
  func update_refreshesList() async {
    // Given
    let createUC = MockCreateUseCase()
    let readUC = MockReadUseCase()
    let updateUC = MockUpdateUseCase()
    let deleteUC = MockDeleteUseCase()

    let store = PrivateMemoStore(
      createUseCase: createUC,
      readUseCase: readUC,
      updateUseCase: updateUC,
      deleteUseCase: deleteUC,
    )

    var updated = false
    updateUC.runHandler = { _ in updated = true }

    var memo = Memo(owner: "user", content: "Original")
    readUC.memos = [memo]
    await store.load()

    // When
    memo.content = "Updated"
    readUC.memos = [memo]
    store.update(memo)

    // Wait for async task
    try? await Task.sleep(for: .milliseconds(100))

    // Then
    #expect(updated)
    #expect(store.memos.first?.content == "Updated")
  }

  @Test("Delete memo refreshes list")
  func delete_refreshesList() async {
    // Given
    let createUC = MockCreateUseCase()
    let readUC = MockReadUseCase()
    let updateUC = MockUpdateUseCase()
    let deleteUC = MockDeleteUseCase()

    let store = PrivateMemoStore(
      createUseCase: createUC,
      readUseCase: readUC,
      updateUseCase: updateUC,
      deleteUseCase: deleteUC,
    )

    var deleted = false
    deleteUC.runHandler = { _ in deleted = true }

    let memo = Memo(owner: "user", content: "To Delete")
    readUC.memos = [memo]
    await store.load()
    #expect(store.memos.count == 1)

    // When
    readUC.memos = [] // Simulate deletion
    store.delete(memo)

    // Wait for async task
    try? await Task.sleep(for: .milliseconds(100))

    // Then
    #expect(deleted)
    #expect(store.memos.isEmpty)
  }
}
