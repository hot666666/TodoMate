//
//  MessageStore.swift
//  Todo
//
//  Created by hs on 6/9/25.
//

import Foundation
import Observation

@Observable
final class MessageStore {
  // MARK: - Dependencies

  private let createMessageUseCase: CreateMessageUseCase
  private let updateMessageUseCase: UpdateMessageUseCase
  private let deleteMessageUseCase: DeleteMessageUseCase
  private let readMessagesUseCase: ReadMessageUseCase
  private let observeMessagesUseCase: ObserveMessageUseCase
  private let readTracker: MessageReadTracker

  // MARK: - State

  private(set) var messages: [GroupMessage] = []
  private(set) var hasUnreadMessages: Bool = false
  private(set) var isLoading: Bool = false
  private(set) var error: AppError?

  init(container: DIContainer) {
    createMessageUseCase = container.createMessageUseCase
    updateMessageUseCase = container.updateMessageUseCase
    deleteMessageUseCase = container.deleteMessageUseCase
    readMessagesUseCase = container.readMessagesUseCase
    observeMessagesUseCase = container.observeMessagesUseCase
    readTracker = container.messageReadTracker
  }

  // MARK: - Public Methods

  @MainActor
  func refresh(groupId: String) async {
    // Message는 cache 이용말고, 서버로부터 로드
    await load(groupId: groupId, useCache: false)
    await observe(groupId: groupId)
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
      print("[MessageStore] - Failed to add message \(message.id): \(error)")
    }
  }

  func update(_ message: GroupMessage, userId: String) {
    do {
      try updateMessageUseCase.run(for: userId, message)
      if let index = messages.firstIndex(where: { $0.id == message.id }) {
        messages[index] = message
      }
    } catch {
      print("[MessageStore] - Failed to update message \(message.id): \(error)")
    }
  }

  func delete(_ message: GroupMessage, userId: String) {
    Task {
      do {
        try await deleteMessageUseCase.run(for: userId, message)
      } catch {
        print("[MessageStore] - Failed to delete message \(message.id): \(error)")
      }
    }
    messages.removeAll(where: { $0.id == message.id })
  }

  @MainActor
  func load(groupId: String, useCache: Bool = true) async {
    isLoading = true
    error = nil

    do {
      messages = try await readMessagesUseCase.run(in: groupId, useCache: useCache)
      // 로드 후 읽지 않은 메시지 확인
      hasUnreadMessages = readTracker.hasUnreadMessages(in: messages)
    } catch {
      print("[MessageStore] - Failed to load messages for group \(groupId): \(error)")
      self.error = AppError.from(error)
    }

    isLoading = false
  }

  @MainActor
  func observe(groupId: String) async {
    for await event in observeMessagesUseCase.run(in: groupId) {
      switch event {
      case let .added(newMessage):
        if !messages.contains(where: { $0.id == newMessage.id }) {
          messages.append(newMessage)
          hasUnreadMessages = readTracker.hasUnreadMessages(in: messages)
        }

      case let .modified(updatedMessage):
        if let index = messages.firstIndex(where: { $0.id == updatedMessage.id }), updatedMessage.updatedAt > messages[index].updatedAt {
          messages[index] = updatedMessage
        }

      case let .removed(removedMessage):
        messages.removeAll(where: { $0.id == removedMessage.id })

      case let .error(error):
        print("[MessageStore] - Error observing messages: \(error)")
      }
    }
  }
}

extension MessageStore {
  static let preview: MessageStore = {
    let store = MessageStore(container: DIContainer.preview)
    store.messages = [.stub]
    return store
  }()
}
