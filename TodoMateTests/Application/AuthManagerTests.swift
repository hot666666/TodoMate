//
//  AuthManagerTests.swift
//  TodoMate
//
//  Created by hs on 3/6/25.
//

import Testing
@testable import TodoMate

private enum TestFixtures {
  static let mockAuthUser = AuthenticatedUser(uid: "test-user", gid: "test-gid")
  static let authenticationUseCaseForSuccess = MockAuthenticationUseCase(
    shouldSignInSuccess: true,
    signInReturn: mockAuthUser
  )
  static let authenticationUseCaseForFailure = MockAuthenticationUseCase(shouldSignInSuccess: false)
  static let fetchAuthenticatedUserUseCaseWithExistingUser =
    MockFetchAuthenticatedUserUseCase(excuteReturn: mockAuthUser)
  static let fetchAuthenticatedUserUseCaseWithoutExistingUser =
    MockFetchAuthenticatedUserUseCase(excuteReturn: nil)
}

@Suite("AuthManager Tests")
struct AuthManagerTests {
  @Suite("SignIn 메서드 테스트")
  struct SignInTests {
    let mockAuthUser = TestFixtures.mockAuthUser
    let fetchAuthenticatedUserUseCase = TestFixtures
      .fetchAuthenticatedUserUseCaseWithoutExistingUser

    @Test("로그인 성공")
    func signInSucceedsWithNoInitialUser() async {
      // Given
      let authManager = AuthManager(
        authenticationUseCase: TestFixtures.authenticationUseCaseForSuccess,
        fetchAuthenticatedUserUseCase: fetchAuthenticatedUserUseCase
      )

      // When
      await authManager.signIn()

      // Then
      #expect(authManager.authenticatedUser != nil, "로그인 후 유저가 존재해야 함")
      switch authManager.state {
      case .signedIn:
        #expect(true, "로그인 성공 후 signedIn 상태여야 함")
      case let state:
        #expect(Bool(false), "로그인 성공 후 signedIn이어야 하지만 현재: \(state)")
      }
    }

    @Test("로그인 실패")
    func signInFailsWithNoInitialUser() async {
      // Given
      let authManager = AuthManager(
        authenticationUseCase: TestFixtures.authenticationUseCaseForFailure,
        fetchAuthenticatedUserUseCase: fetchAuthenticatedUserUseCase
      )

      // When
      await authManager.signIn()

      // Then
      #expect(authManager.authenticatedUser == nil, "로그인 실패 후 유저가 없어야 함")
      switch authManager.state {
      case .signedOut:
        #expect(true, "로그인 실패 후 signedOut 상태여야 함")
      case let state:
        #expect(Bool(false), "로그인 실패 후 signedOut이어야 하지만 현재: \(state)")
      }
    }
  }

  @Suite("SignOut 테스트")
  struct SignOutTests {
    let mockAuthUser = TestFixtures.mockAuthUser

    @Test("로그아웃")
    func signOutWithNoInitialUser() async {
      // Given
      let authManager = AuthManager(
        authenticationUseCase: TestFixtures.authenticationUseCaseForSuccess,
        fetchAuthenticatedUserUseCase: TestFixtures.fetchAuthenticatedUserUseCaseWithExistingUser
      )

      // When
      await authManager.signOut()

      // Then
      #expect(authManager.authenticatedUser == nil, "로그아웃 후 유저가 없어야 함")
      switch authManager.state {
      case .signedOut:
        #expect(true, "로그아웃 후 signedOut 상태여야 함")
      case let state:
        #expect(Bool(false), "로그아웃 후 signedOut이어야 하지만 현재: \(state)")
      }
    }
  }

  @Suite("fetchAUser 메서드 테스트")
  struct fetchAUserTests {
    let mockAuthUser = TestFixtures.mockAuthUser
    let authenticationUseCase = TestFixtures.authenticationUseCaseForSuccess

    @Test("AuthenticatedUser 존재")
    func fetchAUserWithExistingUser() {
      // Given
      let authenticationUseCase = authenticationUseCase
      let fetchAuthenticatedUserUseCase = TestFixtures.fetchAuthenticatedUserUseCaseWithExistingUser

      // When(초기화 시 fetchAUser 호출)
      let authManager = AuthManager(
        authenticationUseCase: authenticationUseCase,
        fetchAuthenticatedUserUseCase: fetchAuthenticatedUserUseCase
      )

      // Then
      #expect(authManager.authenticatedUser != nil, "유저가 존재해야 함")
      switch authManager.state {
      case .signedIn:
        #expect(true, "signedIn 상태여야 함")
      case let state:
        #expect(Bool(false), "signedIn 상태여야 하지만 현재: \(state)")
      }
    }

    @Test("AuthenticatedUser 미존재")
    func fetchAUserWithNoExistingUser() {
      // Given
      let authenticationUseCase = authenticationUseCase
      let fetchAuthenticatedUserUseCase = TestFixtures
        .fetchAuthenticatedUserUseCaseWithoutExistingUser

      // When(초기화 시 fetchAUser 호출)
      let authManager = AuthManager(
        authenticationUseCase: authenticationUseCase,
        fetchAuthenticatedUserUseCase: fetchAuthenticatedUserUseCase
      )

      // Then
      #expect(authManager.authenticatedUser == nil, "유저가 없어야 함")
      switch authManager.state {
      case .signedOut:
        #expect(true, "signedOut 상태여야 함")
      case let state:
        #expect(Bool(false), "signedOut 상태여야 하지만 현재: \(state)")
      }
    }
  }
}
