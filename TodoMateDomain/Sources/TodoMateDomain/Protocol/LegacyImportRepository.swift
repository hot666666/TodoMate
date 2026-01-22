//
//  LegacyImportRepository.swift
//  TodoMate
//
//  Created by hs on 2025-01-23.
//

import Foundation

public protocol LegacyImportRepository: Sendable {
  /// Fetch stored Todos from legacy (Firestore) database with pagination
  /// - Parameters:
  ///   - userId: Target User ID
  ///   - lastSnapshot: The last document snapshot from the previous fetch (for pagination)
  ///   - limit: Number of documents to fetch per batch
  /// - Returns: A tuple containing the fetched Todos and the last snapshot for the next fetch
  func fetchLegacyTodos(userId: String, lastSnapshot: Any?, limit: Int) async throws -> (todos: [Todo], lastSnapshot: Any?)

  /// Fetch stored Memo from legacy (Firestore) database
  /// - Parameter userId: Target User ID
  /// - Returns: The user's memo if exists, otherwise nil
  func fetchLegacyMemo(userId: String) async throws -> Memo?

  /// Fetch total count of legacy todos for progress calculation
  /// - Parameter userId: Target User ID
  /// - Returns: Total count of documents
  func fetchLegacyTodoCount(userId: String) async throws -> Int
}
