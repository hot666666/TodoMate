//
//  ReadUserGroupUseCase.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

public protocol ReadUserGroupUseCase {
  func run(groupId: String, useCache: Bool) async throws -> [User]
}

public final class ReadUserGroupUseCaseImpl: ReadUserGroupUseCase {
  private let userRepository: UserRepository

  public init(userRepository: UserRepository) {
    self.userRepository = userRepository
  }

  public func run(groupId: String, useCache: Bool) async throws -> [User] {
    try await userRepository.readAll(groupId: groupId, useCache: useCache)
  }
}

public final class StubReadUserGroupUseCase: ReadUserGroupUseCase {
  public init() {}
  public func run(groupId _: String, useCache _: Bool) async throws -> [User] {
    User.stubs
  }
}
