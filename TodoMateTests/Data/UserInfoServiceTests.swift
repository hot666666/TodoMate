//
//  UserInfoServiceTests.swift
//  TodoMate
//
//  Created by hs on 3/6/25.
//

import Foundation
import Testing
@testable import TodoMate

@Suite("UserInfoService Tests")
struct UserInfoServiceTests {
  let mockUser = AuthenticatedUser(uid: "test-user", gid: "test-gid")
  let userDefaults: UserDefaults
  let userInfoKey: String

  init() {
    userInfoKey = UUID().uuidString
    userDefaults = UserDefaults.standard
    userDefaults.removePersistentDomain(forName: "TestUserDefaults")
  }

  @Test("UserInfo 로드 성공")
  func testLoadUserInfoSuccess() throws {
    // Given
    let service = UserInfoService(userDefaults: userDefaults, userInfoKey: userInfoKey)
    let encodedData = try JSONEncoder().encode(mockUser)
    userDefaults.set(encodedData, forKey: userInfoKey)

    // When
    let loadedUser = try service.loadUserInfo()

    // Then
    #expect(loadedUser.uid == mockUser.uid, "로드된 유저 정보가 mockUser와 일치해야 함")
  }

  @Test("UserInfo 로드 실패 - 데이터 없음")
  func testLoadUserInfoFailureNoData() throws {
    // Given
    let service = UserInfoService(userDefaults: userDefaults, userInfoKey: userInfoKey)

    // When & Then
    do {
      _ = try service.loadUserInfo()
      #expect(Bool(false), "데이터가 없으면 로드가 실패해야 함")
    } catch UserInfoServiceError.failedToLoad {
      #expect(true, "데이터가 없을 때 failedToLoad 에러가 발생해야 함")
    } catch {
      #expect(Bool(false), "예상치 못한 에러 발생: \(error)")
    }
  }

  @Test("UserInfo 로드 실패 - 디코딩 오류")
  func testLoadUserInfoFailureDecodingError() throws {
    // Given
    let service = UserInfoService(userDefaults: userDefaults, userInfoKey: userInfoKey)
    let invalidData = "invalid data".data(using: .utf8)
    userDefaults.set(invalidData, forKey: userInfoKey)

    // When & Then
    do {
      _ = try service.loadUserInfo()
      #expect(Bool(false), "디코딩 불가능한 데이터면 로드가 실패해야 함")
    } catch UserInfoServiceError.failedToDecode {
      #expect(true, "디코딩 실패 시 failedToDecode 에러가 발생해야 함")
    } catch {
      #expect(Bool(false), "예상치 못한 에러 발생: \(error)")
    }

    // When & Then - 디코딩 실패 시 데이터 삭제 확인
    let loadedData = userDefaults.data(forKey: userInfoKey)

    #expect(loadedData == nil, "이전 디코딩 실패 시 데이터가 삭제되어야 함")
  }
}
