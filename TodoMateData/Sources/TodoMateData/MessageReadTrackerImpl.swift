//
//  MessageReadTrackerImpl.swift
//  Todo
//
//  Created by hs on 6/2/25.
//

import Common
import Foundation
import TodoMateDomain

public final class MessageReadTrackerImpl: MessageReadTracker {
  private var cachedTimestamp: Double = 0
  private let userDefaults: UserDefaults

  public init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
    cachedTimestamp = userDefaults.double(forKey: UserDefaultsKey.lastMessageReadTimestamp.rawValue)
  }

  public func markAsRead() {
    cachedTimestamp = Date().timeIntervalSince1970
    userDefaults.set(cachedTimestamp, forKey: UserDefaultsKey.lastMessageReadTimestamp.rawValue)
  }

  public func hasUnreadMessages(in messages: [GroupMessage]) -> Bool {
    guard let latestMessage = messages.last else { return false }
    return latestMessage.createdAt.timeIntervalSince1970 > cachedTimestamp
  }

  public func clearReadHistory() {
    cachedTimestamp = 0
    userDefaults.removeObject(forKey: UserDefaultsKey.lastMessageReadTimestamp.rawValue)
  }
}
