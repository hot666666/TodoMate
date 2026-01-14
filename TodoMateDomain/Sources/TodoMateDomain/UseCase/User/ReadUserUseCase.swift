//
//  ReadUserUseCase.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

public protocol ReadUserUseCase {
  func run(for userId: String, useCache: Bool) async throws -> User?
}

public final class ReadUserUseCaseImpl: ReadUserUseCase {
  private let userRepository: UserRepository

  public init(userRepository: UserRepository) {
    self.userRepository = userRepository
  }

  public func run(for userId: String, useCache: Bool) async throws -> User? {
    try await userRepository.read(userId: userId, source: useCache ? .cache : .server)
  }
}

public final class StubReadUserUseCase: ReadUserUseCase {
  public init() {}
  public func run(for _: String, useCache _: Bool) async throws -> User? {
    User.stub
  }
}
