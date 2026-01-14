//
//  LocalMemoRepositoryImpl.swift
//  TodoMate
//
//  Created by agent on 1/11/26.
//

import Foundation
import SwiftData
import TodoMateDomain

@ModelActor
public actor SwiftDataMemoRepositoryImpl: MemoRepository {
  // @ModelActor provides `modelContext` and `modelExecutor`

  public func create(_ memo: Memo) async throws {
    let sdMemo = memo.toSDMemo()
    modelContext.insert(sdMemo)
    try modelContext.save()
  }

  public func update(_ memo: Memo) async throws {
    let memoId = memo.id
    let descriptor = FetchDescriptor<SDMemo>(predicate: #Predicate<SDMemo> { $0.id == memoId })

    if let sdMemo = try modelContext.fetch(descriptor).first {
      sdMemo.content = memo.content
      sdMemo.updatedAt = Date()
      try modelContext.save()
    } else {
      try await create(memo)
    }
  }

  public func delete(_ memo: Memo) async throws {
    let memoId = memo.id
    let descriptor = FetchDescriptor<SDMemo>(predicate: #Predicate<SDMemo> { $0.id == memoId })

    if let sdMemo = try modelContext.fetch(descriptor).first {
      modelContext.delete(sdMemo)
      try modelContext.save()
    }
  }

  public func readAllByUserId(_: String, useCache _: Bool) async throws -> [Memo] {
    let descriptor = FetchDescriptor<SDMemo>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
    let sdMemos = try modelContext.fetch(descriptor)
    return sdMemos.map { $0.toDomain() }
  }

  public func readAllByUserIds(_: [String], useCache _: Bool) async throws -> [Memo] {
    []
  }
}
