//
//  AuthenticatedUserCacheServiceType.swift
//  TodoMate
//
//  Created by hs on 2/5/25.
//

protocol AuthenticatedUserCacheServiceType {
  func save(_ userInfo: AuthenticatedUser) throws
  func load() throws -> AuthenticatedUser
  func clear()
}

class StubAuthenticatedUserCacheService: AuthenticatedUserCacheServiceType {
  func save(_ userInfo: AuthenticatedUser) throws {}
  func load() throws -> AuthenticatedUser { .stub }
  func clear() {}
}
