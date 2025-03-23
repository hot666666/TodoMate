//
//  AuthenticatedUserCacheTests.swift
//  TodoMate
//
//  Created by hs on 3/6/25.
//

import Foundation
import Testing
@testable import TodoMate

@Suite("AuthenticatedUserCache Tests")
struct AuthenticatedUserCacheTests {
  let mockUser = AuthenticatedUser(uid: "test-user", gid: "test-gid")
  let userDefaults: UserDefaults
  let cacheKey: String

  init() {
    cacheKey = UUID().uuidString
    userDefaults = UserDefaults.standard
    userDefaults.removePersistentDomain(forName: "TestUserDefaults")
  }

  @Test("AuthenticatedUserCache 로드 성공")
  func testLoadUserInfoSuccess() throws {
    // Given
    let service = AuthenticatedUserCacheService(userDefaults: userDefaults, cacheKey: cacheKey)
    let encodedData = try JSONEncoder().encode(mockUser)
    userDefaults.set(encodedData, forKey: cacheKey)

    // When
    let loadedUser = try service.load()

    // Then
    #expect(loadedUser.uid == mockUser.uid, "로드된 유저 정보가 mockUser와 일치해야 함")
  }

  @Test("AuthenticatedUserCache 로드 실패 - 데이터 없음")
  func testLoadUserInfoFailureNoData() throws {
    // Given
    let service = AuthenticatedUserCacheService(userDefaults: userDefaults, cacheKey: cacheKey)

    // When & Then
    do {
      _ = try service.load()
      #expect(Bool(false), "데이터가 없으면 로드가 실패해야 함")
    } catch AuthenticatedUserCacheServiceError.failedToLoad {
      #expect(true, "데이터가 없을 때 failedToLoad 에러가 발생해야 함")
    } catch {
      #expect(Bool(false), "예상치 못한 에러 발생: \(error)")
    }
  }

  @Test("AuthenticatedUserCache 로드 실패 - 디코딩 오류")
  func testLoadUserInfoFailureDecodingError() throws {
    // Given
    let service = AuthenticatedUserCacheService(userDefaults: userDefaults, cacheKey: cacheKey)
    let invalidData = "invalid data".data(using: .utf8)
    userDefaults.set(invalidData, forKey: cacheKey)

    // When & Then
    do {
      _ = try service.load()
      #expect(Bool(false), "디코딩 불가능한 데이터면 로드가 실패해야 함")
    } catch AuthenticatedUserCacheServiceError.failedToDecode {
      #expect(true, "디코딩 실패 시 failedToDecode 에러가 발생해야 함")
    } catch {
      #expect(Bool(false), "예상치 못한 에러 발생: \(error)")
    }

    // When & Then - 디코딩 실패 시 데이터 삭제 확인
    let loadedData = userDefaults.data(forKey: cacheKey)

    #expect(loadedData == nil, "이전 디코딩 실패 시 데이터가 삭제되어야 함")
  }
}
