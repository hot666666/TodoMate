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
    private let invocation = AwaitableInvocation<Memo>()

    func nextInvocation() async throws -> Memo {
      try await invocation.next()
    }

    func run(_ memo: Memo) async throws {
      invocation.record(memo)
    }
  }

  final class MockUpdateUseCase: UpdateLocalMemoUseCase {
    private let invocation = AwaitableInvocation<Memo>()

    func nextInvocation() async throws -> Memo {
      try await invocation.next()
    }

    func run(_ memo: Memo) async throws {
      invocation.record(memo)
    }
  }

  final class MockDeleteUseCase: DeleteLocalMemoUseCase {
    private let invocation = AwaitableInvocation<Memo>()

    func nextInvocation() async throws -> Memo {
      try await invocation.next()
    }

    func run(_ memo: Memo) async throws {
      invocation.record(memo)
    }
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

  final class MockPermanentlyDeleteUseCase: PermanentlyDeleteItemUseCase {
    func run(_: DeletedItem) async throws {}
    func run(_: [DeletedItem]) async throws {}
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

    // When
    store.add(content: "New Memo")
    let receivedMemo = try await createUC.nextInvocation()

    // Then
    #expect(receivedMemo.content == "New Memo")
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
    // When
    store.update(memo)
    let receivedMemo = try await updateUC.nextInvocation()

    // Then
    #expect(receivedMemo.id == memo.id)
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
    // When
    store.delete(memo)
    let receivedMemo = try await deleteUC.nextInvocation()

    // Then
    #expect(receivedMemo.id == memo.id)
  }
}
