//
//  ReadGroupMemoUseCase.swift
//  Todo
//
//  Created by hs on 7/8/25.
//

protocol ReadGroupMemoUseCase {
  func run(for userIds: [String], useCache: Bool) async throws -> [String: Memo?]
}

final class ReadGroupMemoUseCaseImpl: ReadGroupMemoUseCase {
  private let repository: MemoRepository

  init(repository: MemoRepository) {
    self.repository = repository
  }

  func run(for userIds: [String], useCache: Bool = true) async throws -> [String: Memo?] {
    let memos = try await repository.readByUserIds(userIds, useCache: useCache)
    let groupedMemos = Dictionary(grouping: memos) { $0.owner }
    return Dictionary(uniqueKeysWithValues: userIds.map { userId in
      (userId, groupedMemos[userId]?.first)
    })
  }
}

final class StubReadGroupMemoUseCase: ReadGroupMemoUseCase {
  func run(for userIds: [String], useCache: Bool = true) async throws -> [String: Memo?] {
    let memos = try await StubMemoRepository().readByUserIds(userIds, useCache: useCache)
    let groupedMemos = Dictionary(grouping: memos) { $0.owner }
    return Dictionary(uniqueKeysWithValues: userIds.map { userId in
      (userId, groupedMemos[userId]?.first)
    })
  }
}
