//
//  MessageStore.swift
//  Todo
//
//  Created by hs on 6/9/25.
//

import Observation

@Observable
final class MessageStore {
  // MARK: - Dependencies

  private let createMessageUseCase: CreateMessageUseCase
  private let updateMessageUseCase: UpdateMessageUseCase
  private let deleteMessageUseCase: DeleteMessageUseCase
  private let readMessagesUseCase: ReadMessageUseCase
  private let observeMessagesUseCase: ObserveMessageUseCase

  // MARK: - State

  private(set) var messages: [GroupMessage] = []

  init(container: DIContainer) {
    createMessageUseCase = container.createMessageUseCase
    updateMessageUseCase = container.updateMessageUseCase
    deleteMessageUseCase = container.deleteMessageUseCase
    readMessagesUseCase = container.readMessagesUseCase
    observeMessagesUseCase = container.observeMessagesUseCase
  }

  // MARK: - Public Methods

  @MainActor
  func refresh(groupId: String) async {
    await load(groupId: groupId)
    await observe(groupId: groupId)
  }

  func add(_ message: GroupMessage, userId: String) {
    do {
      try createMessageUseCase.run(for: userId, message)
      messages.insert(message, at: 0)
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
  func load(groupId: String) async {
    do {
      messages = try await readMessagesUseCase.run(in: groupId, useCache: true)
    } catch {
      print("[MessageStore] - Failed to load messages for group \(groupId): \(error)")
    }
  }

  @MainActor
  func observe(groupId: String) async {
    for await event in observeMessagesUseCase.run(in: groupId) {
      switch event {
      case let .added(newMessage):
        if !messages.contains(where: { $0.id == newMessage.id }) {
          messages.insert(newMessage, at: 0)
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
