//
//  ReadUserUseCase.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

protocol ReadUserUseCase {
  func run(for userId: String, useCache: Bool) async throws -> User?
}

final class ReadUserUseCaseImpl: ReadUserUseCase {
  private let userRepository: UserRepository

  init(userRepository: UserRepository) {
    self.userRepository = userRepository
  }

  func run(for userId: String, useCache: Bool) async throws -> User? {
    try await userRepository.read(userId: userId, source: useCache ? .cache : .server)
  }
}

final class StubReadUserUseCase: ReadUserUseCase {
  func run(for _: String, useCache _: Bool) async throws -> User? {
    User.stub
  }
}
