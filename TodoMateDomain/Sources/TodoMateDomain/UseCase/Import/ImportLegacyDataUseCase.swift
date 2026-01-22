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
  private static let batchLimit = 100

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
          // 1. Import Memo
          try await importMemo(userId: userId)

          // 2. Import Todos
          let totalCount = try await legacyRepository.fetchLegacyTodoCount(userId: userId)

          if totalCount == 0 {
            continuation.yield(1.0)
            continuation.finish()
            return
          }

          var processedCount = 0
          var lastSnapshot: Any?

          while true {
            let (todos, snapshot) = try await legacyRepository.fetchLegacyTodos(
              userId: userId,
              lastSnapshot: lastSnapshot,
              limit: Self.batchLimit,
            )

            if todos.isEmpty { break }

            for todo in todos {
              // Check for duplication locally
              if await (try? todoRepository.read(id: todo.id)) != nil {
                // Already exists, skip
              } else {
                try await todoRepository.create(todo)
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

    let memos = try await memoRepository.readAllByUserId(userId, useCache: true)
    if memos.isEmpty {
      try await memoRepository.create(memo)
    }
  }
}
