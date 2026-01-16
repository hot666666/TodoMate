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

  @Test("Add Memo calls CreateUseCase")
  func add_callsUseCase() async throws {
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

    let store = PrivateMemoStore(
      createUseCase: createUC,
      readUseCase: readUC,
      updateUseCase: updateUC,
      deleteUseCase: deleteUC,
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

    let store = PrivateMemoStore(
      createUseCase: createUC,
      readUseCase: readUC,
      updateUseCase: updateUC,
      deleteUseCase: deleteUC,
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
