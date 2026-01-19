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
        sdMemo.isDeleted = true
        sdMemo.updatedAt = Date()
        try modelContext.save()
      }
    } catch {
      throw SwiftDataError.deleteFailed(underlying: error)
    }
  }

  public func read(id: String) async throws -> Memo? {
    let descriptor = FetchDescriptor<SDMemo>(
      predicate: #Predicate<SDMemo> { $0.id == id && !$0.isDeleted })
    do {
      return try modelContext.fetch(descriptor).first?.toDomain()
    } catch {
      throw SwiftDataError.fetchFailed(underlying: error)
    }
  }

  public func readAllByUserId(_: String, useCache _: Bool) async throws -> [Memo] {
    let descriptor = FetchDescriptor<SDMemo>(
      predicate: #Predicate<SDMemo> { !$0.isDeleted },
      sortBy: [SortDescriptor(\.createdAt, order: .reverse)],
    )
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

  public func fetchCount(userId _: String) async throws -> Int {
    let descriptor = FetchDescriptor<SDMemo>(predicate: #Predicate<SDMemo> { !$0.isDeleted })
    do {
      return try modelContext.fetchCount(descriptor)
    } catch {
      throw SwiftDataError.fetchFailed(underlying: error)
    }
  }

  public nonisolated func observeMemos() -> AsyncStream<[Memo]> {
    AsyncStream { continuation in
      let task = Task {
        // Initial fetch
        // Note: For memos, we typically read all for current user or just all local memos.
        // Assuming readAllByUserId with empty string fetches all local memos as per usage context or simplified logic.
        // However, looking at readAllByUserId, it filters by !isDeleted and sorts.
        // Let's use readAllByUserId with empty string as seen in Sidebar usage: diContainer.core.fetchMemoCountUseCase.execute(userId: "")

        let fetchMemos = {
          try await self.readAllByUserId("", useCache: false)
        }

        if let initialMemos = try? await fetchMemos() {
          continuation.yield(initialMemos)
        }

        let center = NotificationCenter.default
        let notifications = center.notifications(named: ModelContext.didSave)

        for await _ in notifications {
          if let updatedMemos = try? await fetchMemos() {
            continuation.yield(updatedMemos)
          }
        }
      }

      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }
}
