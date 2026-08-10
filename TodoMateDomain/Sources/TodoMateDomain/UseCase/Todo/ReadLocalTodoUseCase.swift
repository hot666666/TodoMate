//
//  ReadLocalTodoUseCase.swift
//  TodoMate
//
//  Created by hs on 07/02/25.
//

import Foundation

public protocol ReadLocalTodoUseCase: Sendable {
  func run(date: Date) async throws -> [Todo]
  func run(in range: ClosedRange<Date>) async throws -> [Todo]
  func run(id: String) async throws -> Todo?
}

public final class ReadLocalTodoUseCaseImpl: ReadLocalTodoUseCase {
  private let repository: TodoRepository
  private let calendar: Calendar

  public init(repository: TodoRepository, calendar: Calendar = .current) {
    self.repository = repository
    self.calendar = calendar
  }

  public func run(date: Date) async throws -> [Todo] {
    let startOfDay = calendar.startOfDay(for: date)
    guard let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date)
    else {
      return []
    }

    let query = TodoQuery().dateRange(startOfDay ... endOfDay)
    // useCache is true for local repository (always uses cache)
    return try await repository.readAll(query: query, useCache: true)
  }

  public func run(in range: ClosedRange<Date>) async throws -> [Todo] {
    let query = TodoQuery().dateRange(range)
    // useCache is true for local repository (always uses cache)
    return try await repository.readAll(query: query, useCache: true)
  }

  public func run(id: String) async throws -> Todo? {
    try await repository.read(id: id)
  }
}

public final class StubReadLocalTodoUseCase: ReadLocalTodoUseCase {
  public init() {}

  public func run(date _: Date) async throws -> [Todo] {
    []
  }

  public func run(in _: ClosedRange<Date>) async throws -> [Todo] {
    []
  }

  public func run(id _: String) async throws -> Todo? {
    nil
  }
}
