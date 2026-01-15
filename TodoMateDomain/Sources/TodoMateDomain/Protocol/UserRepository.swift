//
//  UserRepository.swift
//  TodoMate
//
//  Created by hs on 7/12/25.
//

public protocol UserRepository: Sendable {
  func create(_ newUser: User) async throws -> User
  func read(userId: String, useCache: Bool) async throws -> User?
  func readAll(groupId: String, useCache: Bool) async throws -> [User]
  func readAll(useCache: Bool) async throws -> [User]
  func update(_ user: User) async throws
}

// MARK: - StubUserRepository

public final class StubUserRepository: UserRepository, Sendable {
  public let userToReturn: User?

  public init(userToReturn: User? = .stub) {
    self.userToReturn = userToReturn
  }

  public func create(_ newUser: User) async throws -> User { newUser }
  public func read(userId _: String, useCache _: Bool) async throws -> User? { userToReturn }
  public func readAll(groupId _: String, useCache _: Bool) async throws -> [User] {
    User.stubs
  }

  public func readAll(useCache _: Bool) async throws -> [User] { User.stubs }
  public func update(_: User) async throws {}
}
