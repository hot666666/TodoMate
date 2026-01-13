//
//  ReadLocalTodoUseCase.swift
//  TodoMate
//
//  Created by hs on 07/02/25.
//

import Foundation

protocol ReadLocalTodoUseCase {
  func run(date: Date) async throws -> [Todo]
  func run(in range: ClosedRange<Date>) async throws -> [Todo]
}

final class ReadLocalTodoUseCaseImpl: ReadLocalTodoUseCase {
  private let repository: TodoRepository
  private let calendar: Calendar

  init(repository: TodoRepository, calendar: Calendar = .current) {
    self.repository = repository
    self.calendar = calendar
  }

  func run(date: Date) async throws -> [Todo] {
    let startOfDay = calendar.startOfDay(for: date)
    guard let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date)
    else {
      return []
    }

    let query = TodoQuery().dateRange(startOfDay ... endOfDay)
    // source is ignored, placeholder for TodoRepository protocol requirement
    return try await repository.readAll(query: query, source: .cache)
  }

  func run(in range: ClosedRange<Date>) async throws -> [Todo] {
    let query = TodoQuery().dateRange(range)
    // source is ignored, placeholder for TodoRepository protocol requirement
    return try await repository.readAll(query: query, source: .cache)
  }
}

final class StubReadLocalTodoUseCase: ReadLocalTodoUseCase {
  func run(date _: Date) async throws -> [Todo] {
    []
  }

  func run(in _: ClosedRange<Date>) async throws -> [Todo] {
    []
  }
}
