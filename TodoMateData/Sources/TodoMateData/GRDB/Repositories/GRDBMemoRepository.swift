import Common
import Foundation
import GRDB
import TodoMateDomain

public final class GRDBMemoRepository: MemoRepository, Sendable {
  private let database: GRDBDatabase

  public init(database: GRDBDatabase) {
    self.database = database
  }

  public func create(_ memo: Memo) async throws {
    let record = MemoRecord(memo)
    try await database.writer.write { databaseConnection in
      try record.insert(databaseConnection)
    }
  }

  public func update(_ memo: Memo) async throws {
    try await database.writer.write { databaseConnection in
      guard var record = try MemoRecord.fetchOne(databaseConnection, key: memo.id) else {
        throw MemoRecord.recordNotFound(databaseConnection, key: memo.id)
      }
      try record.apply(memo, at: databaseConnection.transactionDate)
      try record.update(databaseConnection)
    }
  }

  public func delete(_ memo: Memo) async throws {
    try await database.writer.write { databaseConnection in
      guard var record = try MemoRecord.fetchOne(databaseConnection, key: memo.id) else { return }
      guard try record.markDeleted(at: databaseConnection.transactionDate) else { return }
      try record.update(databaseConnection)
    }
  }

  public func read(id: String) async throws -> Memo? {
    try await database.writer.read { databaseConnection in
      try MemoRecord
        .filter(MemoRecord.Columns.id == id && MemoRecord.Columns.deletedAt == nil)
        .fetchOne(databaseConnection)?
        .domainValue()
    }
  }

  public func readAllByUserId(_ userId: String, useCache _: Bool) async throws -> [Memo] {
    try await database.writer.read { databaseConnection in
      var request = Self.activeMemos
      if !userId.isEmpty {
        request = request.filter(MemoRecord.Columns.ownerID == userId)
      }
      return try request.fetchAll(databaseConnection).map { $0.domainValue() }
    }
  }

  public func readAllByUserIds(_ userIds: [String], useCache _: Bool) async throws -> [Memo] {
    guard !userIds.isEmpty else { return [] }
    return try await database.writer.read { databaseConnection in
      try Self.activeMemos
        .filter(userIds.contains(MemoRecord.Columns.ownerID))
        .fetchAll(databaseConnection)
        .map { $0.domainValue() }
    }
  }

  public func fetchCount(userId: String) async throws -> Int {
    try await database.writer.read { databaseConnection in
      var request = MemoRecord.filter(MemoRecord.Columns.deletedAt == nil)
      if !userId.isEmpty {
        request = request.filter(MemoRecord.Columns.ownerID == userId)
      }
      return try request.fetchCount(databaseConnection)
    }
  }

  public func observeMemos() -> AsyncStream<[Memo]> {
    database.observe(
      region: .memo,
      fetch: { databaseConnection in
        try Self.activeMemos.fetchAll(databaseConnection).map { $0.domainValue() }
      },
      onError: { error in
        Log.error("Memo database observation failed: \(error)", category: .data)
      },
    )
  }

  private static var activeMemos: QueryInterfaceRequest<MemoRecord> {
    MemoRecord
      .filter(MemoRecord.Columns.deletedAt == nil)
      .order(MemoRecord.Columns.updatedAt.desc)
  }
}
