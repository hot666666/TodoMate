//
//  ChatMessage.swift
//  TodoMate
//
//  Presentation layer model for chat messages.
//
//  Created by agent on 1/5/26.
//

import Foundation

/// Presentation layer model for Chat Messages
struct ChatMessage: Identifiable, Equatable {
  let id: String
  let senderId: String
  var text: String?
  var imageUrl: String?
  var localImageData: Data?
  let timestamp: Date

  init(
    id: String = UUID().uuidString,
    senderId: String,
    text: String? = nil,
    imageUrl: String? = nil,
    localImageData: Data? = nil,
    timestamp: Date = .now,
  ) {
    self.id = id
    self.senderId = senderId
    self.text = text
    self.imageUrl = imageUrl
    self.localImageData = localImageData
    self.timestamp = timestamp
  }

  /// Initialize from Domain GroupMessage entity
  init(from message: GroupMessage, senderId: String) {
    id = message.id
    self.senderId = senderId
    text = message.content
    imageUrl = nil
    localImageData = nil
    timestamp = message.createdAt
  }
}

// MARK: - Mock Data

extension ChatMessage {
  static let mockMessages: [ChatMessage] = [
    ChatMessage(
      id: "1",
      senderId: "user_1",
      text: "Hey team, how's the project going?",
    ),
    ChatMessage(
      id: "2",
      senderId: "user_2",
      text: "Going well! Just finished the UI mockups.",
    ),
    ChatMessage(
      id: "3",
      senderId: "user_3",
      text: "Great work everyone! 🎉",
    ),
    ChatMessage(
      id: "4",
      senderId: "user_1",
      text: "Let's sync up tomorrow at 10am.",
    ),
  ]
}
