//
//  SidebarCacheRepositoryImpl.swift
//  TodoMate
//
//  Created by agent on 1/12/26.
//

import Foundation
import TodoMateDomain

public final class SidebarCacheRepositoryImpl: SidebarCacheRepository {
  private let userDefaults: UserDefaults

  public init(userDefaults: UserDefaults) {
    self.userDefaults = userDefaults
  }

  public func saveProfileName(_ name: String) {
    userDefaults.set(name, forKey: UserDefaultsKey.cachedProfileName.rawValue)
  }

  public func saveGroup(name: String, id: String) {
    userDefaults.set(name, forKey: UserDefaultsKey.cachedGroupName.rawValue)
    userDefaults.set(id, forKey: UserDefaultsKey.cachedUserGroupId.rawValue)
  }

  public func clearGroupCache() {
    userDefaults.removeObject(forKey: UserDefaultsKey.cachedGroupName.rawValue)
    userDefaults.removeObject(forKey: UserDefaultsKey.cachedUserGroupId.rawValue)
  }

  public func clearCache() {
    userDefaults.removeObject(forKey: UserDefaultsKey.cachedProfileName.rawValue)
    userDefaults.removeObject(forKey: UserDefaultsKey.cachedGroupName.rawValue)
    userDefaults.removeObject(forKey: UserDefaultsKey.cachedUserGroupId.rawValue)
  }
}

public enum UserDefaultsKey: String {
  case lastSidebarState
  case lastChatPanelState
  case lastMessageReadTimestamp
  case cachedProfileName
  case cachedGroupName
  case cachedUserGroupId
}
