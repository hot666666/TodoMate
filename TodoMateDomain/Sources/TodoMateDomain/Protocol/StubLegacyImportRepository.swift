//
//  StubLegacyImportRepository.swift
//  TodoMate
//
//  Created by hs on 2025-01-23.
//

import Foundation

public final class StubLegacyImportRepository: LegacyImportRepository, Sendable {
  public init() {}

  public func fetchLegacyTodos(userId _: String, lastSnapshot _: Any?, limit _: Int) async throws -> (todos: [Todo], lastSnapshot: Any?) {
    ([], nil)
  }

  public func fetchLegacyMemo(userId _: String) async throws -> Memo? {
    nil
  }

  public func fetchLegacyTodoCount(userId _: String) async throws -> Int {
    0
  }
}
