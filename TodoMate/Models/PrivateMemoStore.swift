//
//  PrivateMemoStore.swift
//  TodoMate
//
//  Created by agent on 1/11/26.
//

import Common
import Foundation
import Observation
import TodoMateDomain

@Observable
@MainActor
final class PrivateMemoStore {
  // MARK: - Dependencies

  private let createUseCase: CreateLocalMemoUseCase
  private let readUseCase: ReadLocalMemoUseCase
  private let updateUseCase: UpdateLocalMemoUseCase
  private let deleteUseCase: DeleteLocalMemoUseCase

  // MARK: - State

  private(set) var memos: [Memo] = []

  // MARK: - Initialization

  init(
    createUseCase: CreateLocalMemoUseCase,
    readUseCase: ReadLocalMemoUseCase,
    updateUseCase: UpdateLocalMemoUseCase,
    deleteUseCase: DeleteLocalMemoUseCase,
  ) {
    self.createUseCase = createUseCase
    self.readUseCase = readUseCase
    self.updateUseCase = updateUseCase
    self.deleteUseCase = deleteUseCase
  }

  convenience init(container: CoreDIContainer) {
    self.init(
      createUseCase: container.createLocalMemoUseCase,
      readUseCase: container.readLocalMemoUseCase,
      updateUseCase: container.updateLocalMemoUseCase,
      deleteUseCase: container.deleteLocalMemoUseCase,
    )
  }

  // MARK: - Actions

  func load() async {
    do {
      memos = try await readUseCase.run(userId: "").sorted(by: { $0.createdAt > $1.createdAt })
    } catch {
      Log.error("Failed to load private memos: \(error)", category: .data)
    }
  }

  func add(content: String) {
    let localUserId = SessionStore.local.user?.id ?? "local-user"
    let memo = Memo(owner: localUserId, content: content)

    Task {
      do {
        try await createUseCase.run(memo)
        await load() // Reload to reflect changes
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
        await load()
      } catch {
        Log.error("Failed to update private memo: \(error)", category: .data)
      }
    }
  }

  func delete(_ memo: Memo) {
    Task {
      do {
        try await deleteUseCase.run(memo)
        await load()
      } catch {
        Log.error("Failed to delete private memo: \(error)", category: .data)
      }
    }
  }
}

extension PrivateMemoStore {
  static var preview: PrivateMemoStore {
    PrivateMemoStore(container: .preview)
  }
}
