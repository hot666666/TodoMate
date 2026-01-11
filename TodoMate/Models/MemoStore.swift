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
  private let deleteMemoUseCase: DeleteMemoUseCase

  // MARK: - Listener

  @ObservationIgnored private var listener: Task<Void, Never>?

  // MARK: - State

  private(set) var memos: [String: [Memo]] = [:]

  init(container: PublicDIContainer) {
    createMemoUseCase = container.createMemoUseCase
    readGroupMemoUseCase = container.readGroupMemoUseCase
    updateMemoUseCase = container.updateMemoUseCase
    deleteMemoUseCase = container.deleteMemoUseCase
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
          Log.info("Received loggedIn event, loaded memos", category: .data)
        case .loggedOut:
          clear()
          Log.info("Received loggedOut event, cleared memos", category: .data)
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

      for (userId, userMemos) in fetchedMemos {
        memos[userId] = userMemos
      }
    } catch {
      Log.error("Failed to load memos for users \(userIds): \(error)", category: .data)
    }
  }

  /// 새 메모 추가
  func add(content: String, currentUserId: String) {
    do {
      let memo = Memo(owner: currentUserId, content: content)
      try createMemoUseCase.run(for: currentUserId, memo)

      // Optimistic update
      var userMemos = memos[currentUserId] ?? []
      userMemos.insert(memo, at: 0)
      memos[currentUserId] = userMemos
    } catch {
      Log.error("Failed to add memo for user \(currentUserId): \(error)", category: .data)
    }
  }

  /// 기존 메모 업데이트
  func update(_ memo: Memo, currentUserId: String) {
    do {
      let updatedMemo = memo.withUpdatedContent(memo.content)
      try updateMemoUseCase.run(for: currentUserId, updatedMemo)

      // Optimistic update
      if var userMemos = memos[currentUserId],
         let index = userMemos.firstIndex(where: { $0.id == memo.id }) {
        userMemos[index] = updatedMemo
        memos[currentUserId] = userMemos
      }
    } catch {
      Log.error("Failed to update memo for user \(currentUserId): \(error)", category: .data)
    }
  }

  /// 메모 삭제
  func delete(_ memo: Memo, currentUserId: String) async {
    do {
      try await deleteMemoUseCase.run(for: currentUserId, memo)

      // Optimistic update
      if var userMemos = memos[currentUserId] {
        userMemos.removeAll { $0.id == memo.id }
        memos[currentUserId] = userMemos
      }
    } catch {
      Log.error("Failed to delete memo for user \(currentUserId): \(error)", category: .data)
    }
  }

  func clear() {
    memos = [:]
  }
}

extension MemoStore {
  static let preview: MemoStore = {
    let store = MemoStore(container: PublicDIContainer.preview)
    store.memos = [User.stub.id: [.stub]]
    return store
  }()
}
