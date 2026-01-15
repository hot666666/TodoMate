import Foundation
@testable import TodoMateDomain

public actor InMemoryUserRepository: UserRepository {
  public var users: [User] = []
  public var updateCallCount = 0
  public var lastUpdatedUser: User?

  public init() {}

  public func setUsers(_ users: [User]) {
    self.users = users
  }

  public func create(_ newUser: User) async throws -> User {
    users.append(newUser)
    return newUser
  }

  public func read(userId: String, useCache _: Bool) async throws -> User? {
    users.first { $0.id == userId }
  }

  public func readAll(groupId: String, useCache _: Bool) async throws -> [User] {
    users.filter { $0.groupId == groupId }
  }

  public func readAll(useCache _: Bool) async throws -> [User] {
    users
  }

  public func update(_ user: User) async throws {
    updateCallCount += 1
    lastUpdatedUser = user
    if let index = users.firstIndex(where: { $0.id == user.id }) {
      users[index] = user
    }
  }
}
