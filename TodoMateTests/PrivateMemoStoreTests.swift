//
//  PrivateMemoStoreTests.swift
//  TodoMateTests
//
//  Created by agent on 1/14/26.
//
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

  final class MockUpdateUseCase: UpdateLocalMemoUseCase {
    var runHandler: ((Memo) -> Void)?
    func run(_ memo: Memo) async throws { runHandler?(memo) }
  }

  final class MockDeleteUseCase: DeleteLocalMemoUseCase {
    var runHandler: ((Memo) -> Void)?
    func run(_ memo: Memo) async throws { runHandler?(memo) }
  }

  final class MockReadUseCase: ReadLocalMemoUseCase {
    func run(userId _: String) async throws -> [Memo] { [] }
  }

  final class MockObserveUseCase: ObserveMemosUseCase {
    func execute() -> AsyncStream<[Memo]> {
      AsyncStream { continuation in
        continuation.finish()
      }
    }
  }

  final class MockPermanentlyDeleteUseCase: PermanentlyDeleteItemUseCase, @unchecked Sendable {
    var runHandler: (([DeletedItem]) -> Void)?
    func run(_: DeletedItem) async throws {}
    func run(_ items: [DeletedItem]) async throws { runHandler?(items) }
    func runAll() async throws {}
  }

  @Test("Add Memo calls CreateUseCase")
  func add_callsUseCase() async throws {
    // Given
    let createUC = MockCreateUseCase()
    let readUC = MockReadUseCase()
    let updateUC = MockUpdateUseCase()
    let deleteUC = MockDeleteUseCase()
    let observeUC = MockObserveUseCase()
    let permanentlyDeleteUC = MockPermanentlyDeleteUseCase()

    let store = MemoStore(
      createUseCase: createUC,
      readUseCase: readUC,
      updateUseCase: updateUC,
      deleteUseCase: deleteUC,
      observeMemosUseCase: observeUC,
      permanentlyDeleteUseCase: permanentlyDeleteUC,
    )

    var capturedMemo: Memo?
    createUC.runHandler = { capturedMemo = $0 }

    // When
    store.add(content: "New Memo")
    try await Task.sleep(for: .milliseconds(50))

    // Then
    #expect(capturedMemo?.content == "New Memo")
  }

  @Test("Update Memo calls UpdateUseCase")
  func update_callsUseCase() async throws {
    // Given
    let createUC = MockCreateUseCase()
    let readUC = MockReadUseCase()
    let updateUC = MockUpdateUseCase()
    let deleteUC = MockDeleteUseCase()
    let observeUC = MockObserveUseCase()
    let permanentlyDeleteUC = MockPermanentlyDeleteUseCase()

    let store = MemoStore(
      createUseCase: createUC,
      readUseCase: readUC,
      updateUseCase: updateUC,
      deleteUseCase: deleteUC,
      observeMemosUseCase: observeUC,
      permanentlyDeleteUseCase: permanentlyDeleteUC,
    )

    let memo = Memo(owner: "me", content: "Updated")
    var capturedMemo: Memo?
    updateUC.runHandler = { capturedMemo = $0 }

    // When
    store.update(memo)
    try await Task.sleep(for: .milliseconds(50))

    // Then
    #expect(capturedMemo?.id == memo.id)
  }

  @Test("Delete Memo calls DeleteUseCase")
  func delete_callsUseCase() async throws {
    // Given
    let createUC = MockCreateUseCase()
    let readUC = MockReadUseCase()
    let updateUC = MockUpdateUseCase()
    let deleteUC = MockDeleteUseCase()
    let observeUC = MockObserveUseCase()
    let permanentlyDeleteUC = MockPermanentlyDeleteUseCase()

    let store = MemoStore(
      createUseCase: createUC,
      readUseCase: readUC,
      updateUseCase: updateUC,
      deleteUseCase: deleteUC,
      observeMemosUseCase: observeUC,
      permanentlyDeleteUseCase: permanentlyDeleteUC,
    )

    let memo = Memo(owner: "me", content: "Delete me")
    var capturedMemo: Memo?
    deleteUC.runHandler = { capturedMemo = $0 }

    // When
    store.delete(memo)
    try await Task.sleep(for: .milliseconds(50))

    // Then
    #expect(capturedMemo?.id == memo.id)
  }
}
