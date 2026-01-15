//
//  MessageReadTracker.swift
//  Todo
//
//  Created by hs on 6/2/25.
//

public protocol MessageReadTracker {
  func markAsRead()
  func hasUnreadMessages(in messages: [GroupMessage]) -> Bool
  func clearReadHistory()
}

// MARK: - StubMessageReadTracker

public final class StubMessageReadTracker: MessageReadTracker {
  private var isMarkedAsRead: Bool = false

  public init() {}

  public func markAsRead() {
    isMarkedAsRead = true
  }

  public func hasUnreadMessages(in messages: [GroupMessage]) -> Bool {
    !isMarkedAsRead && !messages.isEmpty
  }

  public func clearReadHistory() {
    isMarkedAsRead = false
  }
}
