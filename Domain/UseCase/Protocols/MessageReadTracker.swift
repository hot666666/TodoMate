//
//  MessageReadTracker.swift
//  Todo
//
//  Created by hs on 6/2/25.
//

protocol MessageReadTracker {
  func markAsRead()
  func hasUnreadMessages(in messages: [GroupMessage]) -> Bool
  func clearReadHistory()
}

final class StubMessageReadTracker: MessageReadTracker {
  private var isMarkedAsRead: Bool = false

  func markAsRead() {
    isMarkedAsRead = true
  }

  func hasUnreadMessages(in messages: [GroupMessage]) -> Bool {
    !isMarkedAsRead && !messages.isEmpty
  }

  func clearReadHistory() {
    isMarkedAsRead = false
  }
}
