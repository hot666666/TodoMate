//
//  PrivateMemoStore.swift
//  TodoMate
//
//  Created by agent on 1/11/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class PrivateMemoStore {
  // MARK: - Dependencies

  private let createMemoUseCase: CreateMemoUseCase
  private let readGroupMemoUseCase: ReadGroupMemoUseCase
  private let updateMemoUseCase: UpdateMemoUseCase
  private let deleteMemoUseCase: DeleteMemoUseCase

  // MARK: - State

  private(set) var memos: [Memo] = []

  // MARK: - Initialization

  init(container: CoreDIContainer) {
    // For Private context, we construct UseCases using the Local Repository from CoreDI
    let repository = container.localMemoRepository

    // Use generic UseCase implementations or create specific local ones if logic differs.
    // Assuming standard implementations work with any Repository.
    createMemoUseCase = CreateMemoUseCaseImpl(repository: repository)
    readGroupMemoUseCase = ReadGroupMemoUseCaseImpl(repository: repository)
    updateMemoUseCase = UpdateMemoUseCaseImpl(repository: repository)
    deleteMemoUseCase = DeleteMemoUseCaseImpl(repository: repository)
  }

  // MARK: - Actions

  func load() async {
    // For local, "userId" is less relevant but we need one.
    // Using a fixed local ID or the one from SessionStore.local.
    let localUserId = SessionStore.local.user?.id ?? "local-user"

    do {
      // readGroupMemo returns [String: [Memo]]
      let result = try await readGroupMemoUseCase.run(for: [localUserId], useCache: true)
      // Flatten or pick the user's memos
      memos = result.values.flatMap(\.self).sorted(by: { $0.createdAt > $1.createdAt })
    } catch {
      Log.error("Failed to load private memos: \(error)", category: .data)
    }
  }

  func add(content: String) {
    let localUserId = SessionStore.local.user?.id ?? "local-user"
    let memo = Memo(owner: localUserId, content: content)

    Task {
      do {
        try await createMemoUseCase.run(for: localUserId, memo)
        await load() // Reload to reflect changes
      } catch {
        Log.error("Failed to create private memo: \(error)", category: .data)
      }
    }
  }

  func update(_ memo: Memo) {
    let localUserId = SessionStore.local.user?.id ?? "local-user"
    let updatedMemo = memo.withUpdatedContent(memo.content)

    Task {
      do {
        try await updateMemoUseCase.run(for: localUserId, updatedMemo)
        await load()
      } catch {
        Log.error("Failed to update private memo: \(error)", category: .data)
      }
    }
  }

  func delete(_ memo: Memo) {
    let localUserId = SessionStore.local.user?.id ?? "local-user"

    Task {
      do {
        try await deleteMemoUseCase.run(for: localUserId, memo)
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
