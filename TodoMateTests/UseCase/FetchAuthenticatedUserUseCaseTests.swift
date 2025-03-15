//
//  FetchAuthenticatedUserUseCaseTests.swift
//  TodoMate
//
//  Created by hs on 3/6/25.
//

import Foundation
import Testing
@testable import TodoMate

@Suite("FetchAuthenticatedUserUseCase Tests")
struct FetchAuthenticatedUserUseCaseTests {
  private let mockUser: AuthenticatedUser
  private var mockUserInfoServiceWithUser: MockUserInfoService
  private var mockUserInfoServiceWithoutUser: MockUserInfoService

  init() {
    mockUser = AuthenticatedUser(uid: "1", gid: "")

    mockUserInfoServiceWithUser = MockUserInfoService(existingUserInfo: mockUser)
    mockUserInfoServiceWithoutUser = MockUserInfoService(existingUserInfo: nil)
  }

  @Test("수행 성공 - AuthenticatedUser 존재")
  func testFetchAuthenticatedUserWhenExists() throws {
    // Given
    let useCase = FetchAuthenticatedUserUseCase(userInfoService: mockUserInfoServiceWithUser)

    // When
    let result = useCase.execute()

    // Then
    switch result {
    case let .some(user):
      #expect(user.uid == mockUser.uid, "fetchedUser는 mockUser와 같아야 함")
    case .none:
      #expect(Bool(false), "fetchedUser는 nil이 아니어야 함")
    }
  }

  @Test("수행 성공 - AuthenticatedUser 미존재")
  func testFetchAuthenticatedUserWhenNotExists() {
    // Given
    let useCase = FetchAuthenticatedUserUseCase(userInfoService: mockUserInfoServiceWithoutUser)

    // When
    let result = useCase.execute()

    // Then
    switch result {
    case let .some(user):
      #expect(Bool(false), "fetchedUser는 nil이어야 하지만 유저가 반환됨: \(user.uid)")
    case .none:
      #expect(true, "fetchedUser는 nil이어야 함")
    }
  }
}
