//
//  LoadUserSessionUseCase.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

public enum LoadUserSessionPhase: Sendable {
  case initial // 최초 진입/가입/캐시 우선
  case refresh // 로그인 후/항상 최신 fetch
}

public protocol LoadUserSessionUseCase: Sendable {
  func run(for userId: String, phase: LoadUserSessionPhase) async throws -> UserSession
}

public final class LoadUserSessionUseCaseImpl: LoadUserSessionUseCase {
  private let readUserUseCase: ReadUserUseCase
  private let readUserGroupUseCase: ReadUserGroupUseCase
  private let userRepository: UserRepository

  public init(
    readUserUseCase: ReadUserUseCase,
    readUserGroupUseCase: ReadUserGroupUseCase,
    userRepository: UserRepository,
  ) {
    self.readUserUseCase = readUserUseCase
    self.readUserGroupUseCase = readUserGroupUseCase
    self.userRepository = userRepository
  }

  public func run(for userId: String, phase: LoadUserSessionPhase) async throws -> UserSession {
    switch phase {
    case .initial:
      // 1. 캐시 우선
      if let cachedUser = try? await readUserUseCase.run(for: userId, useCache: true) {
        return try await makeSession(for: cachedUser, useCache: true)
      }
      // 2. 서버에서 fetch
      if let fetchedUser = try await readUserUseCase.run(for: userId, useCache: false) {
        return try await makeSession(for: fetchedUser, useCache: false)
      }
      // 3. 신규 생성
      let newUser = User(id: userId)
      let createdUser = try await userRepository.create(newUser)
      return try await makeSession(for: createdUser, useCache: false)

    case .refresh:
      // 서버에서 fetch
      guard let fetchedUser = try await readUserUseCase.run(for: userId, useCache: false) else {
        throw UserUseCaseError.userNotFound
      }
      return try await makeSession(for: fetchedUser, useCache: false)
    }
  }

  private func makeSession(for user: User, useCache: Bool) async throws -> UserSession {
    let groupMembers = await (try? readUserGroupUseCase.run(groupId: user.groupId, useCache: useCache)) ?? [user]
    return UserSession(currentUser: user, groupMembers: groupMembers)
  }
}

public final class StubLoadUserSessionUseCase: LoadUserSessionUseCase {
  public init() {}
  public func run(for _: String, phase _: LoadUserSessionPhase) async throws -> UserSession {
    UserSession(currentUser: User.stub, groupMembers: User.stubs)
  }
}
