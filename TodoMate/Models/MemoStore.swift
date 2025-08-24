//
//  MemoStore.swift
//  Todo
//
//  Created by hs on 7/9/25.
//

import SwiftUI

@Observable
final class MemoStore {
  // MARK: - Dependencies

  private let createMemoUseCase: CreateMemoUseCase
  private let readGroupMemoUseCase: ReadGroupMemoUseCase
  private let updateMemoUseCase: UpdateMemoUseCase

  // MARK: - State

  private(set) var memos: [String: Memo?] = [:]

  init(container: DIContainer) {
    createMemoUseCase = container.createMemoUseCase
    readGroupMemoUseCase = container.readGroupMemoUseCase
    updateMemoUseCase = container.updateMemoUseCase
  }

  // MARK: - Public Methods

  @MainActor
  func refresh(for userIds: [String]) async {
    await load(for: userIds, useCache: true)
    await load(for: userIds, useCache: false)
  }

  @MainActor
  func load(for userIds: [String], useCache: Bool = true) async {
    do {
      memos = try await readGroupMemoUseCase.run(for: userIds, useCache: useCache)
    } catch {
      print("[MemoVM] - Failed to load memos for users \(userIds): \(error)")
    }
  }

  func save(_ content: String, currentUserId: String) {
    do {
      let existingMemo = memos[currentUserId] ?? nil
      var memo: Memo

      if let existing = existingMemo {
        // 기존 메모 업데이트
        memo = existing.withUpdatedContent(content)
        try updateMemoUseCase.run(for: currentUserId, memo)
      } else {
        // 새 메모 생성
        memo = Memo(owner: currentUserId, content: content)
        try createMemoUseCase.run(for: currentUserId, memo)
      }

      // Optimistic update
      memos[currentUserId] = memo
    } catch {
      print("[MemoVM] - Failed to save memo for user \(currentUserId): \(error)")
    }
  }
}

extension MemoStore {
  static let preview: MemoStore = {
    let store = MemoStore(container: DIContainer.preview)
    store.memos = [User.stub.id: .stub]
    return store
  }()
}
