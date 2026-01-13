//
//  MessageStore.swift
//  TodoMate
//
//  Created by hs on 6/9/25.
//

import SwiftUI

@Observable
@MainActor
final class MessageStore {
  // MARK: - Dependencies

  @ObservationIgnored private let createMessageUseCase: CreateMessageUseCase
  @ObservationIgnored private let updateMessageUseCase: UpdateMessageUseCase
  @ObservationIgnored private let deleteMessageUseCase: DeleteMessageUseCase
  @ObservationIgnored private let readMessagesUseCase: ReadMessageUseCase
  @ObservationIgnored private let observeMessagesUseCase: ObserveMessageUseCase
  @ObservationIgnored private let readTracker: MessageReadTracker

  // MARK: - Listeners

  @ObservationIgnored private var sessionListener: Task<Void, Never>?
  @ObservationIgnored private var messageObserver: Task<Void, Never>?

  // MARK: - State

  private(set) var messages: [GroupMessage] = []
  private(set) var hasUnreadMessages: Bool = false
  private var currentGroupId: String = ""

  init(container: PublicDIContainer) {
    createMessageUseCase = container.createMessageUseCase
    updateMessageUseCase = container.updateMessageUseCase
    deleteMessageUseCase = container.deleteMessageUseCase
    readMessagesUseCase = container.readMessagesUseCase
    observeMessagesUseCase = container.observeMessagesUseCase
    readTracker = container.messageReadTracker
  }

  // MARK: - Subscriber

  /// SessionStore 이벤트 구독 시작
  func startListening(to events: AsyncStream<SessionEvent>) {
    sessionListener?.cancel()
    sessionListener = Task { [weak self] in
      for await event in events {
        guard let self else { return }
        switch event {
        case let .loggedIn(_, groupId, _):
          // groupId는 그룹 채팅방 ID
          await refresh(groupId: groupId)
          Log.info(
            "Received loggedIn event, loading messages for group: \(groupId)", category: .data,
          )
        case .loggedOut:
          clear()
          Log.info("Received loggedOut event, cleared messages", category: .data)
        }
      }
    }
  }

  /// 리스너 정리
  func cleanup() {
    sessionListener?.cancel()
    sessionListener = nil
    messageObserver?.cancel()
    messageObserver = nil
  }

  // MARK: - Public Methods

  func refresh(groupId: String) async {
    currentGroupId = groupId
    // Cache-first: 먼저 캐시에서 빠르게 로드 (오프라인 지원)
    await load(groupId: groupId, useCache: true)
    // 그 다음 서버에서 최신 데이터로 업데이트
    await load(groupId: groupId, useCache: false)
    messageObserver?.cancel()
    messageObserver = Task {
      await observe(groupId: groupId)
    }
  }

  func markAllAsRead() {
    readTracker.markAsRead()
    hasUnreadMessages = false
  }

  func add(_ message: GroupMessage, userId: String) {
    do {
      try createMessageUseCase.run(for: userId, message)
      messages.append(message)
      // 내가 보낸 메시지는 항상 읽음 처리
      markAllAsRead()
    } catch {
      Log.error("Failed to add message \(message.id): \(error)", category: .data)
    }
  }

  func update(_ message: GroupMessage, userId: String) {
    do {
      try updateMessageUseCase.run(for: userId, message)
      if let index = messages.firstIndex(where: { $0.id == message.id }) {
        messages[index] = message
      }
    } catch {
      Log.error("Failed to update message \(message.id): \(error)", category: .data)
    }
  }

  func delete(_ message: GroupMessage, userId: String) {
    Task {
      do {
        try await deleteMessageUseCase.run(for: userId, message)
      } catch {
        Log.error("Failed to delete message \(message.id): \(error)", category: .data)
      }
    }
    messages.removeAll(where: { $0.id == message.id })
  }

  func load(groupId: String, useCache: Bool = true) async {
    do {
      messages = try await readMessagesUseCase.run(in: groupId, useCache: useCache)
      // 로드 후 읽지 않은 메시지 확인
      hasUnreadMessages = readTracker.hasUnreadMessages(in: messages)
    } catch {
      Log.error("Failed to load messages for group \(groupId): \(error)", category: .data)
    }
  }

  func clear() {
    messageObserver?.cancel()
    messages = []
    hasUnreadMessages = false
    currentGroupId = ""
  }

  // MARK: - Private Methods

  private func observe(groupId: String) async {
    for await event in observeMessagesUseCase.run(in: groupId) {
      switch event {
      case let .added(newMessage):
        if !messages.contains(where: { $0.id == newMessage.id }) {
          messages.append(newMessage)
          hasUnreadMessages = readTracker.hasUnreadMessages(in: messages)
        }

      case let .modified(updatedMessage):
        if let index = messages.firstIndex(where: { $0.id == updatedMessage.id }),
           updatedMessage.updatedAt > messages[index].updatedAt {
          messages[index] = updatedMessage
        }

      case let .removed(removedMessage):
        messages.removeAll(where: { $0.id == removedMessage.id })

      case let .error(error):
        Log.error("Error observing messages: \(error)", category: .data)
      }
    }
  }
}

extension MessageStore {
  static let preview: MessageStore = {
    let store = MessageStore(container: PublicDIContainer.preview)
    store.messages = [.stub]
    return store
  }()
}
