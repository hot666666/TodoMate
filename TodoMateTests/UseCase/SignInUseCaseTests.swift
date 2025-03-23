//
//  SignInUseCaseTests.swift
//  TodoMate
//
//  Created by hs on 3/23/25.
//

import Foundation
import Testing
@testable import TodoMate

@Suite("SignInUseCase Tests")
struct SignInUseCaseTests {
  // 테스트에 사용할 mock 사용자 (그룹 정보 포함)
  private let mockUser = User(uid: "uid", nickname: "TestUser", gid: "group1")

  // SignInUseCase에 필요한 모의 객체들
  private var mockAuthServiceSuccess: MockAuthService
  private var mockAuthServiceFailure: MockAuthService
  private var mockAuthenticatedUserCacheService: MockAuthenticatedUserCacheService
  private var mockUserRepository: MockUserRepository
  private var mockUserGroupCacheService: MockUserGroupCacheService

  init() {
    // 로그인 성공용 모의 객체: 성공 시 mockUser를 반환하도록 설정
    mockAuthServiceSuccess = MockAuthService(shouldSignInSuccess: true, signInReturn: mockUser)
    // 로그인 실패용 모의 객체
    mockAuthServiceFailure = MockAuthService(shouldSignInSuccess: false)
    mockAuthenticatedUserCacheService = MockAuthenticatedUserCacheService()
    // 모의 유저 리포지토리: 생성자에 전달된 mockUser를 UserDTO로 변환하여 저장
    mockUserRepository = MockUserRepository(users: [mockUser])
    mockUserGroupCacheService = MockUserGroupCacheService()
  }

  @Test("SignInUseCase: 로그인 성공")
  func test_signIn_success() async throws {
    // Given: 로그인 성공용 모의 객체들을 주입하여 SignInUseCase 생성
    let signInUseCase = SignInUseCase(
      authService: mockAuthServiceSuccess,
      authenticatedUserCacheService: mockAuthenticatedUserCacheService,
      userRepoitory: mockUserRepository,
      userGroupCacheService: mockUserGroupCacheService
    )

    // When: 로그인 실행
    let result = await signInUseCase.execute()

    // Then: 성공 결과 및 반환된 AuthenticatedUser 검증
    switch result {
    case let .success(authenticatedUser):
      #expect(authenticatedUser.uid == mockUser.uid, "로그인 성공 시 반환된 사용자 uid가 일치해야 합니다.")
      #expect(authenticatedUser.gid == mockUser.gid, "로그인 성공 시 반환된 사용자 gid가 일치해야 합니다.")

      // 사용자 캐시에 저장되었는지 검증
      do {
        let cachedUser = try mockAuthenticatedUserCacheService.load()
        #expect(cachedUser.uid == mockUser.uid, "캐시에 저장된 사용자 uid가 일치해야 합니다.")
      } catch {
        #expect(Bool(false), "캐시에서 사용자 로드 실패: \(error)")
      }

      // 그룹 캐시에 저장되었는지 검증
      do {
        let cachedUsers = try mockUserGroupCacheService.load()
        #expect(cachedUsers.count == 1, "그룹 캐시에 저장된 사용자의 수가 1이어야 합니다.")
        #expect(cachedUsers.first?.uid == mockUser.uid, "그룹 캐시에 저장된 사용자의 uid가 일치해야 합니다.")
      } catch {
        #expect(Bool(false), "그룹 캐시 로드 실패: \(error)")
      }

    case let .failure(error):
      #expect(Bool(false), "로그인 성공해야 하지만 에러 발생: \(error)")
    }
  }

  @Test("SignInUseCase: 로그인 실패")
  func test_signIn_failure() async throws {
    // Given: 로그인 실패용 모의 객체들을 주입하여 SignInUseCase 생성
    let signInUseCase = SignInUseCase(
      authService: mockAuthServiceFailure,
      authenticatedUserCacheService: mockAuthenticatedUserCacheService,
      userRepoitory: mockUserRepository,
      userGroupCacheService: mockUserGroupCacheService
    )

    // When: 로그인 실행
    let result = await signInUseCase.execute()

    // Then: 실패 결과 검증
    switch result {
    case .success:
      #expect(Bool(false), "로그인 실패해야 하는데 성공했습니다.")
    case .failure:
      #expect(true, "로그인 실패가 정상적으로 처리되어야 합니다.")

      // 사용자 캐시는 비어있어야 함
      do {
        _ = try mockAuthenticatedUserCacheService.load()
        #expect(Bool(false), "로그인 실패 시 사용자 캐시가 비어있어야 합니다.")
      } catch {
        #expect(true, "로그인 실패 시 사용자 캐시가 비어있어야 합니다.")
      }

      // 그룹 캐시는 비어있어야 함
      do {
        let cachedUsers = try mockUserGroupCacheService.load()
        #expect(cachedUsers.isEmpty, "로그인 실패 시 그룹 캐시가 비어있어야 합니다.")
      } catch {
        #expect(true, "로그인 실패 시 그룹 캐시가 비어있어야 합니다.")
      }
    }
  }
}
