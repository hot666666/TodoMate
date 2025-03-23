//
//  SignInUseCase.swift
//  TodoMate
//
//  Created by hs on 3/22/25.
//

enum SignInUseCaseError: Error {
  case signInFailed(Error)
}

protocol SignInUseCaseType {
  func execute() async -> Result<AuthenticatedUser, SignInUseCaseError>
}

// TODO: - Test SignInUseCase
final class SignInUseCase: SignInUseCaseType {
  private let authService: AuthServiceType
  private let authenticatedUserCacheService: AuthenticatedUserCacheServiceType
  private let userRepoitory: UserRepositoryType
  private let userGroupCacheService: UserGroupCacheServiceType

  init(authService: AuthServiceType,
       authenticatedUserCacheService: AuthenticatedUserCacheServiceType,
       userRepoitory: UserRepositoryType,
       userGroupCacheService: UserGroupCacheServiceType) {
    self.authService = authService
    self.authenticatedUserCacheService = authenticatedUserCacheService
    self.userRepoitory = userRepoitory
    self.userGroupCacheService = userGroupCacheService
  }

  func execute() async -> Result<AuthenticatedUser, SignInUseCaseError> {
    do {
      clearCaches()

      let signedInUser = try await authService.signIn()
      let authenticatedUser = AuthenticatedUser.from(signedInUser)

      try updateUserCache(with: authenticatedUser)

      if let gid = authenticatedUser.gid {
        let groupUsers = try await fetchGroupUsers(for: gid)
        try updateGroupCache(with: groupUsers)
      }

      return .success(authenticatedUser)
    } catch {
      return .failure(.signInFailed(error))
    }
  }

  private func clearCaches() {
    authenticatedUserCacheService.clear()
    userGroupCacheService.clear()
  }

  private func updateUserCache(with authenticatedUser: AuthenticatedUser) throws {
    try authenticatedUserCacheService.save(authenticatedUser)
  }

  private func updateGroupCache(with groupUsers: [User]) throws {
    try userGroupCacheService.save(groupUsers)
  }

  private func fetchGroupUsers(for gid: String) async throws -> [User] {
    return try await userRepoitory.readAll(gid: gid)
      .compactMap { User.from($0) }
  }
}

class StubSignInUseCase: SignInUseCaseType {
  func execute() async -> Result<AuthenticatedUser, SignInUseCaseError> {
    return .success(AuthenticatedUser(uid: "test-user", gid: "test-gid"))
  }
}
