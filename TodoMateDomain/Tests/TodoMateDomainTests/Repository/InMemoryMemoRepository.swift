import Foundation
@testable import TodoMateDomain

public actor InMemoryMemoRepository: MemoRepository {
  public var memos: [Memo] = []

  public var createCallCount = 0
  public var updateCallCount = 0
  public var deleteCallCount = 0
  public var readCallCount = 0

  public init() {}

  public func setMemos(_ memos: [Memo]) {
    self.memos = memos
  }

  public func create(_ memo: Memo) async throws {
    createCallCount += 1
    memos.append(memo)
  }

  public func update(_ memo: Memo) async throws {
    updateCallCount += 1
    if let index = memos.firstIndex(where: { $0.id == memo.id }) {
      memos[index] = memo
    }
  }

  public func delete(_ memo: Memo) async throws {
    deleteCallCount += 1
    memos.removeAll { $0.id == memo.id }
  }

  public func read(id: String) async throws -> Memo? {
    memos.first { $0.id == id }
  }

  public func readAllByUserId(_ userId: String, useCache _: Bool) async throws -> [Memo] {
    readCallCount += 1
    return memos.filter { $0.owner == userId }
  }

  public func readAllByUserIds(_ userIds: [String], useCache _: Bool) async throws -> [Memo] {
    readCallCount += 1
    return memos.filter { userIds.contains($0.owner) }
  }

  public func fetchCount(userId: String) async throws -> Int {
    try await readAllByUserId(userId, useCache: true).count
  }
}
