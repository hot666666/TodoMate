//
//  AuthenticatedUserCacheService.swift
//  TodoMate
//
//  Created by hs on 1/28/25.
//

import Foundation

enum AuthenticatedUserCacheServiceError: Error {
  case failedToDecode
  case failedToEncode
  case failedToLoad
}

class AuthenticatedUserCacheService: AuthenticatedUserCacheServiceType {
  private let userDefaults: UserDefaults
  private let cacheKey: String

  init(userDefaults: UserDefaults = .standard, cacheKey: String = Const.AuthenticatedUserCacheKey) {
    self.userDefaults = userDefaults
    self.cacheKey = cacheKey
  }

  func save(_ userInfo: AuthenticatedUser) throws {
    do {
      let encoded = try JSONEncoder().encode(userInfo)
      userDefaults.set(encoded, forKey: cacheKey)
    } catch {
      throw AuthenticatedUserCacheServiceError.failedToEncode
    }
  }

  func load() throws -> AuthenticatedUser {
    guard let savedData = userDefaults.data(forKey: cacheKey) else {
      throw AuthenticatedUserCacheServiceError.failedToLoad
    }

    do {
      let decoded = try JSONDecoder().decode(AuthenticatedUser.self, from: savedData)
      return decoded
    } catch {
      clear()
      throw AuthenticatedUserCacheServiceError.failedToDecode
    }
  }

  func clear() {
    userDefaults.removeObject(forKey: cacheKey)
  }
}
