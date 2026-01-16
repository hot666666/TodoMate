//
//  LocalTodoRepositoryImpl.swift
//  TodoMate
//
//  Created by hs on 07/02/25.
//

import Foundation
import SwiftData
import TodoMateDomain

@ModelActor
public actor SwiftDataTodoRepositoryImpl: TodoRepository {
  // @ModelActor provides `modelContext` and `modelExecutor`

  public func create(_ todo: Todo) async throws {
    let sdTodo = SDTodo(from: todo)
    modelContext.insert(sdTodo)
    do {
      try modelContext.save()
    } catch {
      throw SwiftDataError.saveFailed(underlying: error)
    }
  }

  public func update(_ todo: Todo) async throws {
    let id = todo.id
    let descriptor = FetchDescriptor<SDTodo>(predicate: #Predicate { $0.id == id })

    do {
      if let existing = try modelContext.fetch(descriptor).first {
        existing.content = todo.content
        existing.statusRawValue = todo.status.rawValue
        existing.detail = todo.detail
        existing.date = todo.date
        existing.updatedAt = Date()
        existing.owner = todo.owner
      }
    } catch {
      throw SwiftDataError.fetchFailed(underlying: error)
    }

    do {
      try modelContext.save()
    } catch {
      throw SwiftDataError.saveFailed(underlying: error)
    }
  }

  public func delete(_ todoId: String) async throws {
    let descriptor = FetchDescriptor<SDTodo>(predicate: #Predicate { $0.id == todoId })
    do {
      if let existing = try modelContext.fetch(descriptor).first {
        existing.isDeleted = true
        existing.updatedAt = Date()
      }
    } catch {
      throw SwiftDataError.fetchFailed(underlying: error)
    }

    do {
      try modelContext.save()
    } catch {
      throw SwiftDataError.deleteFailed(underlying: error)
    }
  }

  public func read(id: String) async throws -> Todo? {
    let descriptor = FetchDescriptor<SDTodo>(predicate: #Predicate { $0.id == id && !$0.isDeleted })
    do {
      return try modelContext.fetch(descriptor).first?.toDomain()
    } catch {
      throw SwiftDataError.fetchFailed(underlying: error)
    }
  }

  public func readAll(query: TodoQuery, useCache _: Bool) async throws -> [Todo] {
    var dateRange: ClosedRange<Date>?
    for filter in query.filters {
      if case let .dateRange(range) = filter {
        dateRange = range
      }
    }

    let descriptor: FetchDescriptor<SDTodo>
    if let dateRange {
      let start = dateRange.lowerBound
      let end = dateRange.upperBound
      descriptor = FetchDescriptor<SDTodo>(
        predicate: #Predicate<SDTodo> { $0.date >= start && $0.date <= end && !$0.isDeleted },
        sortBy: [SortDescriptor(\.date)],
      )
    } else {
      descriptor = FetchDescriptor<SDTodo>(
        predicate: #Predicate<SDTodo> { !$0.isDeleted },
        sortBy: [SortDescriptor(\.date)],
      )
    }

    do {
      let allSDTodos = try modelContext.fetch(descriptor)
      return allSDTodos.map { $0.toDomain() }
    } catch {
      throw SwiftDataError.fetchFailed(underlying: error)
    }
  }

  public func fetchCount(query: TodoQuery) async throws -> Int {
    var dateRange: ClosedRange<Date>?
    for filter in query.filters {
      if case let .dateRange(range) = filter {
        dateRange = range
      }
    }

    let descriptor: FetchDescriptor<SDTodo>
    if let dateRange {
      let start = dateRange.lowerBound
      let end = dateRange.upperBound
      descriptor = FetchDescriptor<SDTodo>(
        predicate: #Predicate<SDTodo> { $0.date >= start && $0.date <= end && !$0.isDeleted },
      )
    } else {
      descriptor = FetchDescriptor<SDTodo>(
        predicate: #Predicate<SDTodo> { !$0.isDeleted },
      )
    }

    do {
      return try modelContext.fetchCount(descriptor)
    } catch {
      throw SwiftDataError.fetchFailed(underlying: error)
    }
  }
}
