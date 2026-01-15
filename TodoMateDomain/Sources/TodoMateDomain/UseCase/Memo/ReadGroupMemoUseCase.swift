//
//  ReadGroupMemoUseCase.swift
//  Todo
//
//  Created by hs on 7/8/25.
//

public protocol ReadGroupMemoUseCase {
  func run(for userIds: [String], useCache: Bool) async throws -> [String: [Memo]]
}

public final class ReadGroupMemoUseCaseImpl: ReadGroupMemoUseCase {
  private let repository: MemoRepository

  public init(repository: MemoRepository) {
    self.repository = repository
  }

  public func run(for userIds: [String], useCache: Bool = true) async throws -> [String: [Memo]] {
    let memos = try await repository.readAllByUserIds(userIds, useCache: useCache)
    let groupedMemos = Dictionary(grouping: memos) { $0.owner }
    // Ensure all userIds have an entry, even if empty
    return Dictionary(
      uniqueKeysWithValues: userIds.map { userId in
        (userId, groupedMemos[userId] ?? [])
      })
  }
}

public final class StubReadGroupMemoUseCase: ReadGroupMemoUseCase {
  public init() {}
  public func run(for userIds: [String], useCache: Bool = true) async throws -> [String: [Memo]] {
    let memos = try await StubMemoRepository().readAllByUserIds(userIds, useCache: useCache)
    let groupedMemos = Dictionary(grouping: memos) { $0.owner }
    return Dictionary(
      uniqueKeysWithValues: userIds.map { userId in
        (userId, groupedMemos[userId] ?? [])
      })
  }
}
