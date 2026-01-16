//
//  LocalMemoRepositoryTests.swift
//  TodoMateDataTests
//
//  Created by agent on 1/14/26.
//

import Foundation
import SwiftData
import Testing
import TodoMateDomain

@testable import TodoMateData

@Suite("Local Memo Repository Tests", .serialized)
@MainActor
struct LocalMemoRepositoryTests {
  let repository: SwiftDataMemoRepositoryImpl
  let container: ModelContainer
  let testUserId = "local-user"

  init() async throws {
    // Setup in-memory SwiftData container
    let schema = Schema([SDMemo.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    container = try ModelContainer(for: schema, configurations: [config])
    repository = SwiftDataMemoRepositoryImpl(modelContainer: container)
  }

  // MARK: - Create & Read

  @Test("Creates and reads a single memo locally")
  func createAndReadMemo() async throws {
    let memo = Memo(owner: testUserId, content: "Local Memo")
    try await repository.create(memo)

    let results = try await repository.readAllByUserId(testUserId, useCache: false)

    let found = results.first { $0.id == memo.id }
    #expect(found != nil)
    #expect(found?.content == "Local Memo")
  }

  // MARK: - Update

  @Test("Updates existing memo locally")
  func updateMemo() async throws {
    var memo = Memo(owner: testUserId, content: "Original")
    try await repository.create(memo)

    memo = memo.withUpdatedContent("Updated")
    try await repository.update(memo)

    let results = try await repository.readAllByUserId(testUserId, useCache: false)
    let updated = results.first { $0.id == memo.id }

    #expect(updated?.content == "Updated")
  }

  // MARK: - Delete

  @Test("Deletes memo locally")
  func deleteMemo() async throws {
    let memo = Memo(owner: testUserId, content: "To be deleted")
    try await repository.create(memo)

    try await repository.delete(memo)

    let results = try await repository.readAllByUserId(testUserId, useCache: false)
    #expect(!results.contains { $0.id == memo.id })
  }

  // MARK: - Fetch Count

  @Test("Fetches memo count respecting isDeleted")
  func fetchCount() async throws {
    let now = Date()

    // 1. One active
    let memo1 = Memo(
      id: UUID().uuidString,
      content: "Active",
      createdAt: now,
      updatedAt: now,
      owner: testUserId,
      isDeleted: false,
    )

    // 2. One deleted
    let memo2 = Memo(
      id: UUID().uuidString,
      content: "Deleted",
      createdAt: now,
      updatedAt: now,
      owner: testUserId,
      isDeleted: true,
    )

    try await repository.create(memo1)
    try await repository.create(memo2)

    let count = try await repository.fetchCount(userId: testUserId)

    #expect(count == 1)
  }
}
