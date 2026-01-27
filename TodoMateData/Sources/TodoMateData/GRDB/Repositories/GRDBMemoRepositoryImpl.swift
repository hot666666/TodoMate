import Foundation
import GRDB
import TodoMateDomain

public final class GRDBMemoRepositoryImpl: MemoRepository, Sendable {
  private let dbWriter: any DatabaseWriter

  public init(dbWriter: any DatabaseWriter) {
    self.dbWriter = dbWriter
  }

  public func create(_ memo: Memo) async throws {
    let grdbMemo = GRDBMemo(from: memo)
    try await dbWriter.write { db in
      try grdbMemo.insert(db)
    }
  }

  public func update(_ memo: Memo) async throws {
    let grdbMemo = GRDBMemo(from: memo)
    try await dbWriter.write { db in
      if try GRDBMemo.exists(db, key: memo.id) {
        try grdbMemo.update(db)
      } else {
        try grdbMemo.insert(db)
      }
    }
  }

  public func delete(_ memo: Memo) async throws {
    try await dbWriter.write { db in
      if var existing = try GRDBMemo.fetchOne(db, key: memo.id) {
        existing.isDeleted = true
        existing.updatedAt = Date()
        try existing.update(db)
      }
    }
  }

  public func read(id: String) async throws -> Memo? {
    try await dbWriter.read { db in
      try GRDBMemo
        .filter(Column("id") == id && !Column("isDeleted"))
        .fetchOne(db)?
        .toDomain()
    }
  }

  public func readAllByUserId(_ userId: String, useCache: Bool) async throws -> [Memo] {
    // Note: userId is currently unused in the SwiftData implementation for local filter,
    // it just fetches all non-deleted.
    // However, the interface has userId.
    // The SwiftData impl: `predicate: #Predicate<SDMemo> { !$0.isDeleted }`
    // It ignores userId. I will follow the same behavior for now, or match SwiftData impl.
    // "Let's use readAllByUserId with empty string as seen in Sidebar usage: diContainer.core.fetchMemoCountUseCase.execute(userId: "")"
    // So it seems it just gets all local memos.

    try await dbWriter.read { db in
      try GRDBMemo
        .filter(!Column("isDeleted"))
        .order(Column("createdAt").desc)
        .fetchAll(db)
        .map { $0.toDomain() }
    }
  }

  public func readAllByUserIds(_ userIds: [String], useCache: Bool) async throws -> [Memo] {
    []
  }

  public func fetchCount(userId: String) async throws -> Int {
    try await dbWriter.read { db in
      try GRDBMemo
        .filter(!Column("isDeleted"))
        .fetchCount(db)
    }
  }

  public func observeMemos() -> AsyncStream<[Memo]> {
    let request = GRDBMemo
      .filter(!Column("isDeleted"))
      .order(Column("createdAt").desc)

    let observation = ValueObservation.tracking { db in
      try request.fetchAll(db).map { $0.toDomain() }
    }

    return AsyncStream { continuation in
      let cancellable = observation.start(in: dbWriter, onError: { error in
        print("GRDB Observation error: \(error)")
      }, onChange: { memos in
        continuation.yield(memos)
      })

      continuation.onTermination = { _ in
        cancellable.cancel()
      }
    }
  }
}
