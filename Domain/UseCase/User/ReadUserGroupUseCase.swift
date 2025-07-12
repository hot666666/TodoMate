//
//  ReadUserGroupUseCase.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

protocol ReadUserGroupUseCase {
  func run(groupId: String, useCache: Bool) async throws -> [User]
}

final class ReadUserGroupUseCaseImpl: ReadUserGroupUseCase {
  private let userRepository: UserRepository

  init(userRepository: UserRepository) {
    self.userRepository = userRepository
  }

  func run(groupId: String, useCache: Bool) async throws -> [User] {
    try await userRepository.readAll(groupId: groupId, source: useCache ? .cache : .server)
  }
}

final class StubReadUserGroupUseCase: ReadUserGroupUseCase {
  func run(groupId _: String, useCache _: Bool) async throws -> [User] {
    User.stubs
  }
}
