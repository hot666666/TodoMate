//
//  LocalMemoRepositoryTests.swift
//  TodoMateDataTests
//
//  Created by agent on 1/14/26.
//

import Foundation
import Testing
@testable import TodoMateData
import TodoMateDomain

@Suite("Local Memo Repository Tests", .serialized)
struct LocalMemoRepositoryTests {
  let database: GRDBDatabase
  let repository: GRDBMemoRepository
  let testUserId = "local-user"

  init() async throws {
    database = try GRDBDatabase(storage: .inMemory)
    repository = GRDBMemoRepository(database: database)
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
    let originalDate = Date(timeIntervalSince1970: 1)
    var memo = Memo(
      content: "Original",
      createdAt: originalDate,
      updatedAt: originalDate,
      owner: testUserId,
    )
    try await repository.create(memo)

    memo = memo.withUpdatedContent("Updated")
    try await repository.update(memo)

    let results = try await repository.readAllByUserId(testUserId, useCache: false)
    let updated = results.first { $0.id == memo.id }

    #expect(updated?.content == "Updated")
    #expect(updated?.updatedAt ?? originalDate > originalDate)

    let memoID = memo.id
    let record = try await database.writer.read { databaseConnection in
      try MemoRecord.fetchOne(databaseConnection, key: memoID)
    }
    #expect(record?.createdAt == originalDate)
    #expect(record?.localRevision == 2)
  }

  @Test("Updating a missing memo fails")
  func updateMissingMemoFails() async throws {
    let memo = Memo(owner: testUserId, content: "Missing")
    var didThrow = false
    do {
      try await repository.update(memo)
    } catch {
      didThrow = true
    }
    #expect(didThrow)
  }

  @Test("Rejects an update after the memo was deleted")
  func updateDeletedMemoFails() async throws {
    var memo = Memo(owner: testUserId, content: "Original")
    try await repository.create(memo)
    try await repository.delete(memo)

    memo = memo.withUpdatedContent("Stale update")
    var didThrow = false
    do {
      try await repository.update(memo)
    } catch {
      didThrow = true
    }

    #expect(didThrow)
    let memoID = memo.id
    let record = try await database.writer.read { databaseConnection in
      try MemoRecord.fetchOne(databaseConnection, key: memoID)
    }
    #expect(record?.content == "Original")
    #expect(record?.deletedAt != nil)
    #expect(record?.localRevision == 2)
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

  @Test("Reads memos for the requested owners")
  func readsMemosForRequestedOwners() async throws {
    try await repository.create(Memo(owner: testUserId, content: "Mine"))
    try await repository.create(Memo(owner: "other", content: "Other"))

    let oneOwner = try await repository.readAllByUserId(testUserId, useCache: false)
    let multipleOwners = try await repository.readAllByUserIds(["other"], useCache: false)

    #expect(oneOwner.map(\.content) == ["Mine"])
    #expect(multipleOwners.map(\.content) == ["Other"])
  }

  @Test("Observation emits database changes")
  func observationEmitsChanges() async throws {
    let stream = repository.observeMemos()
    var iterator = stream.makeAsyncIterator()
    #expect(await iterator.next()?.isEmpty == true)

    try await repository.create(Memo(owner: testUserId, content: "Observed"))

    let updated = await iterator.next()
    #expect(updated?.map(\.content) == ["Observed"])
  }
}
