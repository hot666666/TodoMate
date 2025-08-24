//
//  MessageReadTrackerImpl.swift
//  Todo
//
//  Created by hs on 6/2/25.
//

import Foundation

final class MessageReadTrackerImpl: MessageReadTracker {
  private var cachedTimestamp: Double = 0
  private let userDefaultsKey = "lastMessageReadTimestamp"

  init() {
    cachedTimestamp = UserDefaults.standard.double(forKey: userDefaultsKey)
  }

  func markAsRead() {
    cachedTimestamp = Date().timeIntervalSince1970
    UserDefaults.standard.set(cachedTimestamp, forKey: userDefaultsKey)
  }

  func hasUnreadMessages(in messages: [GroupMessage]) -> Bool {
    guard let latestMessage = messages.last else { return false }
    return latestMessage.createdAt.timeIntervalSince1970 > cachedTimestamp
  }

  func clearReadHistory() {
    cachedTimestamp = 0
    UserDefaults.standard.removeObject(forKey: userDefaultsKey)
  }
}
