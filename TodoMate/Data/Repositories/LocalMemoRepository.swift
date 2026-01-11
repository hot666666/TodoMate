//
//  LocalMemoRepository.swift
//  TodoMate
//
//  Created by agent on 1/11/26.
//

import Foundation
import SwiftData

struct LocalMemoRepository: MemoRepository {
  private let modelContext: ModelContext

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }

  func create(_ memo: Memo) throws {
    let sdMemo = memo.toSDMemo()
    modelContext.insert(sdMemo)
    try modelContext.save()
  }

  func update(_ memo: Memo) throws {
    let memoId = memo.id
    let descriptor = FetchDescriptor<SDMemo>(predicate: #Predicate<SDMemo> { $0.id == memoId })

    if let sdMemo = try modelContext.fetch(descriptor).first {
      sdMemo.content = memo.content
      sdMemo.updatedAt = Date()
      try modelContext.save()
    } else {
      // If not found, treat as create
      try create(memo)
    }
  }

  func delete(_ memo: Memo) async throws {
    let memoId = memo.id
    let descriptor = FetchDescriptor<SDMemo>(predicate: #Predicate<SDMemo> { $0.id == memoId })

    if let sdMemo = try modelContext.fetch(descriptor).first {
      modelContext.delete(sdMemo)
      try modelContext.save()
    }
  }

  func readAllByUserId(_: String, useCache _: Bool) async throws -> [Memo] {
    let descriptor = FetchDescriptor<SDMemo>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
    let sdMemos = try modelContext.fetch(descriptor)
    return sdMemos.map { $0.toDomain() }
  }

  func readAllByUserIds(_: [String], useCache: Bool) async throws -> [Memo] {
    try await readAllByUserId("local", useCache: useCache)
  }
}
