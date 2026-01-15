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
    do {
      try modelContext.save()
    } catch {
      throw SwiftDataError.saveFailed(underlying: error)
    }
  }

  public func update(_ memo: Memo) async throws {
    let memoId = memo.id
    let descriptor = FetchDescriptor<SDMemo>(predicate: #Predicate<SDMemo> { $0.id == memoId })

    do {
      if let sdMemo = try modelContext.fetch(descriptor).first {
        sdMemo.content = memo.content
        sdMemo.updatedAt = Date()
        try modelContext.save()
      } else {
        try await create(memo)
      }
    } catch let error as SwiftDataError {
      throw error
    } catch {
      throw SwiftDataError.saveFailed(underlying: error)
    }
  }

  public func delete(_ memo: Memo) async throws {
    let memoId = memo.id
    let descriptor = FetchDescriptor<SDMemo>(predicate: #Predicate<SDMemo> { $0.id == memoId })

    do {
      if let sdMemo = try modelContext.fetch(descriptor).first {
        modelContext.delete(sdMemo)
        try modelContext.save()
      }
    } catch {
      throw SwiftDataError.deleteFailed(underlying: error)
    }
  }

  public func readAllByUserId(_: String, useCache _: Bool) async throws -> [Memo] {
    let descriptor = FetchDescriptor<SDMemo>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
    do {
      let sdMemos = try modelContext.fetch(descriptor)
      return sdMemos.map { $0.toDomain() }
    } catch {
      throw SwiftDataError.fetchFailed(underlying: error)
    }
  }

  public func readAllByUserIds(_: [String], useCache _: Bool) async throws -> [Memo] {
    []
  }
}
