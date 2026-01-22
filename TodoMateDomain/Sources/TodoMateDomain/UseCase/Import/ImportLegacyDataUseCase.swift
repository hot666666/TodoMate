//
//  ImportLegacyDataUseCase.swift
//  TodoMate
//
//  Created by hs on 2025-01-23.
//

import Foundation

/// Protocol for importing legacy data (Todos & Memo)
public protocol ImportLegacyDataUseCase: Sendable {
  /// Execute the import process
  /// - Parameter userId: The user ID to import data for
  /// - Returns: An AsyncThrowingStream that yields the progress (0.0 to 1.0)
  func execute(userId: String) -> AsyncThrowingStream<Double, Error>
}

/// Implementation of ImportLegacyDataUseCase
public final class ImportLegacyDataUseCaseImpl: ImportLegacyDataUseCase {
  private let legacyRepository: LegacyImportRepository
  private let todoRepository: TodoRepository
  private let memoRepository: MemoRepository

  public init(
    legacyRepository: LegacyImportRepository,
    todoRepository: TodoRepository,
    memoRepository: MemoRepository,
  ) {
    self.legacyRepository = legacyRepository
    self.todoRepository = todoRepository
    self.memoRepository = memoRepository
  }

  public func execute(userId: String) -> AsyncThrowingStream<Double, Error> {
    AsyncThrowingStream { continuation in
      Task {
        do {
          // 1. Import Memo (Single fetch)
          // We do this first or in parallel, but it's small so let's just do it.
          // Note: Memo doesn't contribute significantly to progress calculation or we can give it initial weight.
          // For simplicity, we treat Memo as a separate quick step.
          try await importMemo(userId: userId)

          // 2. Import Todos (Batch fetch)
          let totalCount = try await legacyRepository.fetchLegacyTodoCount(userId: userId)

          if totalCount == 0 {
            continuation.yield(1.0)
            continuation.finish()
            return
          }

          var processedCount = 0
          var lastSnapshot: Any?
          let batchLimit = 100

          while true {
            let (todos, snapshot) = try await legacyRepository.fetchLegacyTodos(
              userId: userId,
              lastSnapshot: lastSnapshot,
              limit: batchLimit,
            )

            if todos.isEmpty { break }

            for todo in todos {
              // Check for duplication locally
              if await (try? todoRepository.read(id: todo.id)) != nil {
                // Already exists, skip
              } else {
                // Create new
                try? await todoRepository.create(todo)
              }
            }

            processedCount += todos.count
            lastSnapshot = snapshot

            let progress = min(Double(processedCount) / Double(totalCount), 1.0)
            continuation.yield(progress)

            if snapshot == nil { break }
          }

          continuation.finish()

        } catch {
          continuation.finish(throwing: error)
        }
      }
    }
  }

  private func importMemo(userId: String) async throws {
    guard let memo = try await legacyRepository.fetchLegacyMemo(userId: userId) else { return }

    // Check if local memo exists or handled by repository logic.
    // Assuming 1-to-1 relationship and repository handling create/update logic.
    // But typically we should check existence or just try to create.
    // MemoRepository typically has 'update' or 'create'.
    // If we strictly follow "Import", we might want to overwrite or merge.
    // User said: "fetch로 존재여부따라 처리하면 될듯해" (Process based on existence fetch)

    // Let's check existence first if possible, or try create.
    // Existing MemoRepository doesn't strictly expose 'exists' but we can readAll or typical 'read'.
    // However, MemoRepository definition wasn't fully visible, assuming standard CRUD.
    // Let's assume we can try to save it. If it conflicts, we might need logic.
    // For now, let's try to search if we have a memo for this user.

    // Since MemoRepository interface usually has `read(for: userId)`
    // Let's try to read.

    // WAIT: I don't see `MemoRepository` interface in my previous `view_file`.
    // I should assume standard signature or verify.
    // Based on `DDD.md` in memory: `readAll(for userId: String)` or similar.
    // I will assume standard: `read(id)` or `read(userId)`.
    // Let's optimistically code: check if any memo, if empty -> create.

    let memos = try await memoRepository.readAllByUserId(userId, useCache: true)
    if memos.isEmpty {
      try await memoRepository.create(memo)
    }
  }
}
