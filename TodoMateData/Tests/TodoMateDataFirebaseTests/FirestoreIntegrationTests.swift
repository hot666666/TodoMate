//
//  FirestoreIntegrationTests.swift
//  TodoMateDataTests
//
//  Created by agent on 1/14/26.
//

import Testing

@testable import TodoMateData

/// 모든 Firestore 통합 테스트를 포함하는 상위 Suite
/// .serialized: 이 Suite 내의 모든 하위 Suite가 순차적으로 실행됨을 보장
@Suite("Firestore Integration Tests", .serialized)
struct FirestoreIntegrationTests {
  /// 각 테스트 실행 전 공통 초기화 로직 (에뮬레이터 설정 및 DB 리셋)
  static func setup() async throws {
    // 에뮬레이터 모드로 Firebase 초기화 (plist 불필요)
    FirebaseEmulatorConfigurator.configure()

    // FirestoreReference가 아직 초기화되지 않았다면 에뮬레이터 모드로 초기화
    if FirestoreReference.shared == nil {
      FirestoreReference.shared = FirestoreReference(emulator: ())
    }

    // 테스트 데이터 초기화
    try await FirestoreReference.shared.resetAllCollections()
  }
}
