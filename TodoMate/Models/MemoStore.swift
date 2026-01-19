//
//  MemoStore.swift
//  TodoMate
//
//  Created by agent on 1/11/26.
//
//

import Common
import Foundation
import Observation
import TodoMateDomain

@Observable
@MainActor
final class MemoStore {
  var memos: [Memo] = []

  // MARK: - Dependencies

  private let createUseCase: CreateLocalMemoUseCase
  private let readUseCase: ReadLocalMemoUseCase
  private let updateUseCase: UpdateLocalMemoUseCase
  private let deleteUseCase: DeleteLocalMemoUseCase
  private let observeMemosUseCase: ObserveMemosUseCase

  private var observationTask: Task<Void, Never>?

  // MARK: - Initialization

  init(
    createUseCase: CreateLocalMemoUseCase,
    readUseCase: ReadLocalMemoUseCase,
    updateUseCase: UpdateLocalMemoUseCase,
    deleteUseCase: DeleteLocalMemoUseCase,
    observeMemosUseCase: ObserveMemosUseCase,
  ) {
    self.createUseCase = createUseCase
    self.readUseCase = readUseCase
    self.updateUseCase = updateUseCase
    self.deleteUseCase = deleteUseCase
    self.observeMemosUseCase = observeMemosUseCase

    updateObservation()
  }

  convenience init(container: CoreDIContainer) {
    self.init(
      createUseCase: container.createLocalMemoUseCase,
      readUseCase: container.readLocalMemoUseCase,
      updateUseCase: container.updateLocalMemoUseCase,
      deleteUseCase: container.deleteLocalMemoUseCase,
      observeMemosUseCase: container.observeMemosUseCase,
    )
  }

  // MARK: - Observation

  func updateObservation() {
    observationTask?.cancel()
    observationTask = Task {
      for await newMemos in observeMemosUseCase.execute() {
        self.memos = newMemos
      }
    }
  }

  // MARK: - Actions

  func add(content: String) {
    let localUserId = SessionStore.local.user?.id ?? "local-user"
    let memo = Memo(owner: localUserId, content: content)

    Task {
      do {
        try await createUseCase.run(memo)

      } catch {
        Log.error("Failed to create private memo: \(error)", category: .data)
      }
    }
  }

  func update(_ memo: Memo) {
    let updatedMemo = memo.withUpdatedContent(memo.content)

    Task {
      do {
        try await updateUseCase.run(updatedMemo)

      } catch {
        Log.error("Failed to update private memo: \(error)", category: .data)
      }
    }
  }

  func delete(_ memo: Memo) {
    Task {
      do {
        try await deleteUseCase.run(memo)

      } catch {
        Log.error("Failed to delete private memo: \(error)", category: .data)
      }
    }
  }
}

extension MemoStore {
  static var preview: MemoStore {
    MemoStore(container: .preview)
  }
}
