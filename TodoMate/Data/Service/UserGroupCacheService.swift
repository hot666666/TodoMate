//
//  UserGroupCacheService.swift
//  TodoMate
//
//  Created by hs on 3/22/25.
//

import Foundation

enum UserGroupCacheServiceError: Error {
  case failedToDecode
  case failedToEncode
  case failedToLoad
}

protocol UserGroupCacheServiceType {
  func load() throws -> [User]
  func save(_ users: [User]) throws
  func clear()
}

final class UserGroupCacheService: UserGroupCacheServiceType {
  private let userDefaults: UserDefaults
  private let cacheKey: String

  init(userDefaults: UserDefaults = .standard, cacheKey: String = Const.UserGroupCacheKey) {
    self.userDefaults = userDefaults
    self.cacheKey = cacheKey
  }

  func load() throws -> [User] {
    guard let data = userDefaults.data(forKey: cacheKey) else {
      throw UserGroupCacheServiceError.failedToLoad
    }

    do {
      let users = try JSONDecoder().decode([User].self, from: data)
      print("✅ 캐시된 유저그룹 불러옴: \(users)")
      return users
    } catch {
      throw UserGroupCacheServiceError.failedToDecode
    }
  }

  func save(_ users: [User]) throws {
    do {
      let data = try JSONEncoder().encode(users)
      userDefaults.set(data, forKey: cacheKey)
      print("✅ 유저그룹 캐시 저장 완료")
    } catch {
      print("❌ 캐시 저장 실패: \(error)")
      clear()
      throw UserGroupCacheServiceError.failedToEncode
    }
  }

  func clear() {
    userDefaults.removeObject(forKey: cacheKey)
    print("🗑️ 유저그룹 캐시 삭제 완료")
  }
}

class StubUserGroupCacheService: UserGroupCacheServiceType {
  func load() throws -> [User] {
    return User.stub
  }

  func save(_ users: [User]) throws {
    print("저장된 유저그룹: \(users)")
  }

  func clear() {
    print("캐시 삭제")
  }
}
