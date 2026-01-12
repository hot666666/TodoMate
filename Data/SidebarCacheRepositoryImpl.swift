//
//  SidebarCacheRepositoryImpl.swift
//  TodoMate
//
//  Created by agent on 1/12/26.
//

import Foundation

final class SidebarCacheRepositoryImpl: SidebarCacheRepository {
  private let userDefaults: UserDefaults

  init(userDefaults: UserDefaults) {
    self.userDefaults = userDefaults
  }

  func saveProfileName(_ name: String) {
    userDefaults.set(name, for: .cachedProfileName)
    Log.info("Sidebar cache updated: profileName = \(name)", category: .cache)
  }

  func saveGroup(name: String, id: String) {
    userDefaults.set(name, for: .cachedGroupName)
    userDefaults.set(id, for: .cachedUserGroupId)
    Log.info("Sidebar cache updated: groupName = \(name), groupId = \(id)", category: .cache)
  }

  func clearGroupCache() {
    userDefaults.removeObject(forKey: UserDefaultsKey.cachedGroupName.rawValue)
    userDefaults.removeObject(forKey: UserDefaultsKey.cachedUserGroupId.rawValue)
    Log.info("Sidebar group cache cleared", category: .cache)
  }

  func clearCache() {
    userDefaults.removeObject(forKey: UserDefaultsKey.cachedProfileName.rawValue)
    userDefaults.removeObject(forKey: UserDefaultsKey.cachedGroupName.rawValue)
    userDefaults.removeObject(forKey: UserDefaultsKey.cachedUserGroupId.rawValue)
    Log.info("Sidebar cache cleared", category: .cache)
  }
}
