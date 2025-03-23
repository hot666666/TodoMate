//
//  SignOutUseCaseTests.swift
//  TodoMate
//
//  Created by hs on 3/23/25.
//

import Foundation
import Testing
@testable import TodoMate

@Suite("SignOutUseCase Tests")
struct SignOutUseCaseTests {
  // SignOutUseCase에 필요한 모의 객체들
  private var mockAuthService: MockAuthService
  private var mockAuthenticatedUserCacheService: MockAuthenticatedUserCacheService
  private var mockUserGroupCacheService: MockUserGroupCacheService
  private var mockWidgetDataManager: MockWidgetDataManager

  init() {
    // 로그아웃 테스트에서는 signOut 호출이 정상적으로 이루어지기만 하면 되므로,
    // 성공 여부와 상관없이 동작하는 모의 객체를 사용합니다.
    mockAuthService = MockAuthService(shouldSignInSuccess: true)
    mockAuthenticatedUserCacheService = MockAuthenticatedUserCacheService()
    mockUserGroupCacheService = MockUserGroupCacheService()
    mockWidgetDataManager = MockWidgetDataManager()
  }

  @Test("SignOutUseCase: 로그아웃 및 캐시 클리어")
  func test_signOut() async throws {
    // Given: 캐시에 임의의 사용자 정보와 그룹 정보를 저장하여, 로그아웃 시 클리어되는지 확인
    let dummyUser = AuthenticatedUser(uid: "uid", gid: "group1")
    try? mockAuthenticatedUserCacheService.save(dummyUser)
    try? mockUserGroupCacheService.save([User(uid: "uid", nickname: "TestUser", gid: "group1")])

    let signOutUseCase = SignOutUseCase(
      authService: mockAuthService,
      authenticatedUserCacheService: mockAuthenticatedUserCacheService,
      userGroupCacheService: mockUserGroupCacheService,
      widgetDataManager: mockWidgetDataManager
    )

    // When: 로그아웃 실행
    await signOutUseCase.execute()

    // Then:
    // 1. widgetDataManager의 removeAll() 호출 여부
    #expect(mockWidgetDataManager.savedTodo == nil, "WidgetDataManager의 removeAll이 호출되어야 합니다.")
    // 2. authService의 signOut() 호출 여부
    #expect(mockAuthService.didSignedOut, "AuthService의 signOut이 호출되어야 합니다.")
    // 3. 캐시 클리어 여부
    #expect(mockAuthenticatedUserCacheService.isCleared, "AuthenticatedUserCache가 클리어되어야 합니다.")
    #expect(mockUserGroupCacheService.isCleared, "UserGroupCache가 클리어되어야 합니다.")
  }
}
