//
//  LegacyImportRepositoryIntegrationTests.swift
//  TodoMateDataTests
//
//  Created by hs on 2025-01-23.
//

import FirebaseFirestore
import XCTest

@testable import TodoMateData
@testable import TodoMateDomain

final class LegacyImportRepositoryIntegrationTests: XCTestCase {
  var repository: LegacyImportRepositoryImpl!
  var db: Firestore!
  let userId = "integration-test-user-legacy"

  override func setUp() async throws {
    try await super.setUp()

    // Configure FirestoreReference for Emulator
    // Note: In a real test suite, this might have been called once globally.
    // We assume it returns safe if already configured or we force it if possible.
    // However, FirestoreReference.configure checks `_instance == nil`.
    // If other tests ran before, it might be set.
    // Since we can't reset the singleton easily without backdoor, we try to access shared,
    // and if it crashes/errors we might need a workaround.
    // BUT since this is a separate test bundle run (test-data-integration), it starts fresh.

    // Check if configured, if not, configure.
    // Since `_instance` is private, we blindly call configure.
    await FirestoreReference.configure(mode: .emulator)

    let firestoreRef = await FirestoreReference.shared
    db = firestoreRef.db

    // Ensure emulator settings are applied if not already by FirestoreReference init
    // FirestoreReference(emulator: ()) does `Firestore.firestore()` and sets mode via init impl?
    // Let's check init: `db = Firestore.firestore()`
    // We usually need to set settings.host for emulator manually or use `FIRESTORE_EMULATOR_HOST` env var.
    // `just start-emulator` usually sets env var?
    // Actually, `FirestoreReference` doesn't seem to set settings.host explicitly in the code I saw.
    // I should set it here to be safe if env var isn't picked up.

    let settings = FirestoreSettings()
    settings.host = "127.0.0.1:8080"
    settings.isSSLEnabled = false
    settings.cacheSettings = MemoryCacheSettings()
    db.settings = settings

    repository = LegacyImportRepositoryImpl(reference: firestoreRef)

    // Clear test data
    try await firestoreRef.resetAllCollections()
  }

  override func tearDown() async throws {
    let firestoreRef = await MainActor.run { FirestoreReference.shared }
    try await firestoreRef.resetAllCollections()
    try await super.tearDown()
  }

  func test_FetchLegacyTodos_Pagination() async throws {
    // Given
    // Use the Collections defined in FirestoreReference
    let todoCollection = await FirestoreReference.shared.todoCollection()

    // Seed 15 todos (limit 10)
    for i in 1 ... 15 {
      let todoData: [String: Any] = [
        "owner": userId, // LegacyImportRepository queries by 'owner'
        "content": "Legacy Todo \(i)",
        "date": Timestamp(date: Date()),
        "status": "시작 전", // TodoStatus rawValue
        "createdAt": Timestamp(date: Date()),
        "updatedAt": Timestamp(date: Date()),
        "isDeleted": false,
        "detail": "",
      ]
      try await todoCollection.addDocument(data: todoData)
    }

    // When - First Page
    let result1 = try await repository.fetchLegacyTodos(
      userId: userId, lastSnapshot: nil, limit: 10,
    )

    // Then
    XCTAssertEqual(result1.todos.count, 10)
    XCTAssertNotNil(result1.lastSnapshot)

    // When - Second Page
    let result2 = try await repository.fetchLegacyTodos(
      userId: userId, lastSnapshot: result1.lastSnapshot, limit: 10,
    )

    // Then
    XCTAssertEqual(result2.todos.count, 5)
    XCTAssertNotNil(result2.lastSnapshot)

    // When - Third Page (Empty)
    if result2.lastSnapshot != nil {
      let result3 = try await repository.fetchLegacyTodos(
        userId: userId, lastSnapshot: result2.lastSnapshot, limit: 10,
      )
      XCTAssertEqual(result3.todos.count, 0)
    }
  }

  func test_FetchLegacyMemo_ReturnsMemo() async throws {
    // Given
    let memoCollection = await FirestoreReference.shared.memoCollection()

    let memoData: [String: Any] = [
      "owner": userId,
      "content": "Legacy Memo Content",
      "updatedAt": Timestamp(date: Date()),
      "createdAt": Timestamp(date: Date()),
    ]
    try await memoCollection.addDocument(data: memoData)

    // When
    let memo = try await repository.fetchLegacyMemo(userId: userId)

    // Then
    XCTAssertNotNil(memo)
    XCTAssertEqual(memo?.content, "Legacy Memo Content")
  }

  // Helper to safely access shared instance in teardown if needed
  // Note: resetAllCollections is cleaner than manual flush
}
