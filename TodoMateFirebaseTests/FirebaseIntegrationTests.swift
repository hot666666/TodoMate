//
//  FirebaseIntegrationTests.swift
//  TodoMateFirebaseTests
//
//  Created by agent on 1/9/26.
//

import Testing

@testable import TodoMate

/// 모든 Firebase 통합 테스트를 포함하는 상위 Suite
/// .serialized: 이 Suite 내의 모든 하위 Suite(테스트 파일들)가 순차적으로 실행됨을 보장
@Suite("All Firebase Integration Tests", .serialized)
struct FirebaseIntegrationTests {
  /// 각 테스트 실행 전 공통 초기화 로직 (DB 리셋 등)
  static func setup() async throws {
    #if USE_FIREBASE_EMULATOR
      try await FirestoreReference().resetAllCollections()
    #endif
  }
}
