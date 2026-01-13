//
//  MessageReadTrackerImpl.swift
//  Todo
//
//  Created by hs on 6/2/25.
//

import Foundation

final class MessageReadTrackerImpl: MessageReadTracker {
  private var cachedTimestamp: Double = 0
  private let userDefaults: UserDefaults

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
    cachedTimestamp = userDefaults.double(for: .lastMessageReadTimestamp)
  }

  func markAsRead() {
    cachedTimestamp = Date().timeIntervalSince1970
    userDefaults.set(cachedTimestamp, for: .lastMessageReadTimestamp)
  }

  func hasUnreadMessages(in messages: [GroupMessage]) -> Bool {
    guard let latestMessage = messages.last else { return false }
    return latestMessage.createdAt.timeIntervalSince1970 > cachedTimestamp
  }

  func clearReadHistory() {
    cachedTimestamp = 0
    userDefaults.removeObject(for: .lastMessageReadTimestamp)
  }
}
