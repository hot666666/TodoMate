//
//  DeletedItemsRepositoryImpl.swift
//  TodoMateData
//
//  Created by agent on 1/22/26.
//

import Foundation
import SwiftData
import TodoMateDomain

/// SwiftData implementation of DeletedItemsRepository.
/// Fetches, restores, and permanently deletes soft-deleted SDTodo and SDMemo items.
@ModelActor
public actor DeletedItemsRepositoryImpl: DeletedItemsRepository {
  // @ModelActor provides `modelContext` and `modelExecutor`

  public func fetchAll() async throws -> [DeletedItem] {
    // Fetch deleted todos
    let todoDescriptor = FetchDescriptor<SDTodo>(
      predicate: #Predicate<SDTodo> { $0.isDeleted },
      sortBy: [SortDescriptor(\.updatedAt, order: .reverse)],
    )

    // Fetch deleted memos
    let memoDescriptor = FetchDescriptor<SDMemo>(
      predicate: #Predicate<SDMemo> { $0.isDeleted },
      sortBy: [SortDescriptor(\.updatedAt, order: .reverse)],
    )

    do {
      let deletedTodos = try modelContext.fetch(todoDescriptor)
      let deletedMemos = try modelContext.fetch(memoDescriptor)

      // Combine and sort by updatedAt (deletion date) descending
      let todoItems = deletedTodos.map { DeletedItem.todo($0.toDomain()) }
      let memoItems = deletedMemos.map { DeletedItem.memo($0.toDomain()) }

      return (todoItems + memoItems).sorted { $0.deletedAt > $1.deletedAt }
    } catch {
      throw SwiftDataError.fetchFailed(underlying: error)
    }
  }

  public func restore(_ item: DeletedItem) async throws {
    switch item {
    case let .todo(todo):
      try await restoreTodo(id: todo.id)
    case let .memo(memo):
      try await restoreMemo(id: memo.id)
    }
  }

  public func permanentlyDelete(_ item: DeletedItem) async throws {
    switch item {
    case let .todo(todo):
      try await deleteTodoPermanently(id: todo.id)
    case let .memo(memo):
      try await deleteMemoPermanently(id: memo.id)
    }
  }

  public func permanentlyDeleteAll() async throws {
    // Delete all deleted todos
    let todoDescriptor = FetchDescriptor<SDTodo>(
      predicate: #Predicate<SDTodo> { $0.isDeleted },
    )

    // Delete all deleted memos
    let memoDescriptor = FetchDescriptor<SDMemo>(
      predicate: #Predicate<SDMemo> { $0.isDeleted },
    )

    do {
      let deletedTodos = try modelContext.fetch(todoDescriptor)
      let deletedMemos = try modelContext.fetch(memoDescriptor)

      for todo in deletedTodos {
        modelContext.delete(todo)
      }

      for memo in deletedMemos {
        modelContext.delete(memo)
      }

      try modelContext.save()
    } catch {
      throw SwiftDataError.deleteFailed(underlying: error)
    }
  }

  // MARK: - Private Helpers

  private func restoreTodo(id: String) async throws {
    let descriptor = FetchDescriptor<SDTodo>(predicate: #Predicate { $0.id == id })

    do {
      if let existing = try modelContext.fetch(descriptor).first {
        existing.isDeleted = false
        existing.updatedAt = Date()
        try modelContext.save()
      }
    } catch {
      throw SwiftDataError.saveFailed(underlying: error)
    }
  }

  private func restoreMemo(id: String) async throws {
    let descriptor = FetchDescriptor<SDMemo>(predicate: #Predicate { $0.id == id })

    do {
      if let existing = try modelContext.fetch(descriptor).first {
        existing.isDeleted = false
        existing.updatedAt = Date()
        try modelContext.save()
      }
    } catch {
      throw SwiftDataError.saveFailed(underlying: error)
    }
  }

  private func deleteTodoPermanently(id: String) async throws {
    let descriptor = FetchDescriptor<SDTodo>(predicate: #Predicate { $0.id == id })

    do {
      if let existing = try modelContext.fetch(descriptor).first {
        modelContext.delete(existing)
        try modelContext.save()
      }
    } catch {
      throw SwiftDataError.deleteFailed(underlying: error)
    }
  }

  private func deleteMemoPermanently(id: String) async throws {
    let descriptor = FetchDescriptor<SDMemo>(predicate: #Predicate { $0.id == id })

    do {
      if let existing = try modelContext.fetch(descriptor).first {
        modelContext.delete(existing)
        try modelContext.save()
      }
    } catch {
      throw SwiftDataError.deleteFailed(underlying: error)
    }
  }
}
