//
//  LegacyImportRepositoryIntegrationTests.swift
//  TodoMateDataTests
//
//  Created by hs on 2025-01-23.
//

import FirebaseFirestore
import Testing

@testable import TodoMateData
@testable import TodoMateDomain

@Suite("Legacy Import Repository Integration Tests", .serialized)
struct LegacyImportRepositoryIntegrationTests {
  var repository: LegacyImportRepositoryImpl!
  var db: Firestore!
  let userId = "integration-test-user-legacy"

  init() async throws {
    // Configure FirestoreReference for Emulator
    await FirestoreReference.configure(mode: .emulator)

    // Setup shared instance
    let firestoreRef = await FirestoreReference.shared
    db = firestoreRef.db

    // Ensure emulator settings are applied
    let settings = FirestoreSettings()
    settings.host = "127.0.0.1:8080"
    settings.isSSLEnabled = false
    settings.cacheSettings = MemoryCacheSettings()
    db.settings = settings

    repository = LegacyImportRepositoryImpl(reference: firestoreRef)

    // Clear test data before running test
    try await firestoreRef.resetAllCollections()
  }

  @Test("Pagination: Fetches legacy todos in batches")
  func fetchLegacyTodosPagination() async throws {
    // Given
    let todoCollection = await FirestoreReference.shared.todoCollection()

    // Seed 15 todos (limit 10)
    for i in 1 ... 15 {
      let todoData: [String: Any] = [
        "owner": userId,
        "content": "Legacy Todo \(i)",
        "date": Timestamp(date: Date()),
        "status": "시작 전",
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
    #expect(result1.todos.count == 10)
    #expect(result1.lastSnapshot != nil)

    // When - Second Page
    let result2 = try await repository.fetchLegacyTodos(
      userId: userId, lastSnapshot: result1.lastSnapshot, limit: 10,
    )

    // Then
    #expect(result2.todos.count == 5)
    #expect(result2.lastSnapshot != nil)

    // When - Third Page (Empty)
    if result2.lastSnapshot != nil {
      let result3 = try await repository.fetchLegacyTodos(
        userId: userId, lastSnapshot: result2.lastSnapshot, limit: 10,
      )
      #expect(result3.todos.count == 0)
    }
  }

  @Test("Fetches single legacy memo correctly")
  func fetchLegacyMemo() async throws {
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
    #expect(memo != nil)
    #expect(memo?.content == "Legacy Memo Content")
  }
}
