//
//  MemoStore.swift
//  TodoMate
//
//  Created by hs on 7/9/25.
//

import SwiftUI

@Observable
@MainActor
final class MemoStore {
  // MARK: - Dependencies

  private let createMemoUseCase: CreateMemoUseCase
  private let readGroupMemoUseCase: ReadGroupMemoUseCase
  private let updateMemoUseCase: UpdateMemoUseCase

  // MARK: - Listener

  @ObservationIgnored private var listener: Task<Void, Never>?

  // MARK: - State

  private(set) var memos: [String: Memo?] = [:]

  init(container: DIContainer) {
    createMemoUseCase = container.createMemoUseCase
    readGroupMemoUseCase = container.readGroupMemoUseCase
    updateMemoUseCase = container.updateMemoUseCase
  }

  // MARK: - Subscriber

  /// SessionStore 이벤트 구독 시작
  func startListening(to events: AsyncStream<SessionEvent>) {
    listener?.cancel()
    listener = Task { [weak self] in
      for await event in events {
        guard let self else { return }
        switch event {
        case let .loggedIn(_, _, memberIds):
          // Cache-first: 먼저 캐시에서 빠르게 로드 (오프라인 지원)
          await load(for: memberIds, useCache: true)
          // 그 다음 서버에서 최신 데이터로 업데이트
          await load(for: memberIds, useCache: false)
          print("[MemoStore] - Received loggedIn event, loaded memos")
        case .loggedOut:
          clear()
          print("[MemoStore] - Received loggedOut event, cleared memos")
        }
      }
    }
  }

  /// 리스너 정리
  func cleanup() {
    listener?.cancel()
    listener = nil
  }

  // MARK: - Public Methods

  func refresh(for userIds: [String]) async {
    await load(for: userIds, useCache: true)
    await load(for: userIds, useCache: false)
  }

  func load(for userIds: [String], useCache: Bool = true) async {
    do {
      let fetchedMemos = try await readGroupMemoUseCase.run(for: userIds, useCache: useCache)

      for (userId, memo) in fetchedMemos {
        if let memo {
          memos[userId] = memo
        }
      }
    } catch {
      print("[MemoStore] - Failed to load memos for users \(userIds): \(error)")
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
      print("[MemoStore] - Failed to save memo for user \(currentUserId): \(error)")
    }
  }

  func clear() {
    memos = [:]
  }
}

extension MemoStore {
  static let preview: MemoStore = {
    let store = MemoStore(container: DIContainer.preview)
    store.memos = [User.stub.id: .stub]
    return store
  }()
}
