import Common
import Foundation
import GRDB
import TodoMateDomain

public final class GRDBMemoRepository: MemoRepository, Sendable {
  private let writer: any DatabaseWriter

  public init(database: GRDBDatabase) {
    writer = database.writer
  }

  public func create(_ memo: Memo) async throws {
    let record = MemoRecord(memo)
    try await writer.write { databaseConnection in
      try record.insert(databaseConnection)
    }
  }

  public func update(_ memo: Memo) async throws {
    let record = MemoRecord(memo)
    try await writer.write { databaseConnection in
      try record.update(databaseConnection)
    }
  }

  public func delete(_ memo: Memo) async throws {
    try await writer.write { databaseConnection in
      guard var record = try MemoRecord.fetchOne(databaseConnection, key: memo.id) else { return }
      record.isDeleted = true
      record.updatedAt = .now
      try record.update(databaseConnection)
    }
  }

  public func read(id: String) async throws -> Memo? {
    try await writer.read { databaseConnection in
      try MemoRecord
        .filter(Column("id") == id && !Column("isDeleted"))
        .fetchOne(databaseConnection)?
        .domainValue()
    }
  }

  public func readAllByUserId(_ userId: String, useCache _: Bool) async throws -> [Memo] {
    try await writer.read { databaseConnection in
      var request = Self.activeMemos
      if !userId.isEmpty {
        request = request.filter(Column("owner") == userId)
      }
      return try request.fetchAll(databaseConnection).map { $0.domainValue() }
    }
  }

  public func readAllByUserIds(_ userIds: [String], useCache _: Bool) async throws -> [Memo] {
    guard !userIds.isEmpty else { return [] }
    return try await writer.read { databaseConnection in
      try Self.activeMemos
        .filter(userIds.contains(Column("owner")))
        .fetchAll(databaseConnection)
        .map { $0.domainValue() }
    }
  }

  public func fetchCount(userId: String) async throws -> Int {
    try await writer.read { databaseConnection in
      var request = MemoRecord.filter(!Column("isDeleted"))
      if !userId.isEmpty {
        request = request.filter(Column("owner") == userId)
      }
      return try request.fetchCount(databaseConnection)
    }
  }

  public func observeMemos() -> AsyncStream<[Memo]> {
    let observation = ValueObservation.tracking { databaseConnection in
      try Self.activeMemos.fetchAll(databaseConnection).map { $0.domainValue() }
    }

    return AsyncStream { continuation in
      let task = Task {
        do {
          for try await memos in observation.values(in: writer) {
            continuation.yield(memos)
          }
        } catch is CancellationError {
          // Stream termination cancels the observation task.
        } catch {
          Log.error("Memo database observation failed: \(error)", category: .data)
        }
        continuation.finish()
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  private static var activeMemos: QueryInterfaceRequest<MemoRecord> {
    MemoRecord
      .filter(!Column("isDeleted"))
      .order(Column("updatedAt").desc)
  }
}
