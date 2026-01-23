//
//  LegacyImportRepositoryImpl.swift
//  TodoMate
//
//  Created by hs on 2025-01-23.
//

import Common
import FirebaseFirestore
import Foundation
import TodoMateDomain

public final class LegacyImportRepositoryImpl: LegacyImportRepository, @unchecked Sendable {
  private let reference: FirestoreReference

  public init(reference: FirestoreReference) {
    self.reference = reference
  }

  public func fetchLegacyTodos(
    userId: String,
    lastSnapshot: Any?,
    limit: Int,
  ) async throws -> (todos: [Todo], lastSnapshot: Any?) {
    var query = reference.todoCollection()
      .whereField("owner", isEqualTo: userId)
      .order(by: "date", descending: false)
      .limit(to: limit)

    if let lastSnapshot = lastSnapshot as? DocumentSnapshot {
      query = query.start(afterDocument: lastSnapshot)
    }

    do {
      let snapshot = try await query.getDocuments(source: .server)
      let todos = snapshot.documents.compactMap { try? $0.data(as: Todo.self) }
      let lastDoc = snapshot.documents.last
      return (todos, lastDoc)
    } catch {
      throw FirestoreRepositoryError.readFailed(underlying: error)
    }
  }

  public func fetchLegacyMemo(userId: String) async throws -> Memo? {
    // Legacy logic: 1 user has 1 memo (usually).
    // Structure: Memos collection -> find where owner == userId
    // Since id might not be constant or known, we query by owner.
    let query = reference.memoCollection()
      .whereField("owner", isEqualTo: userId)
      .limit(to: 1)

    do {
      let snapshot = try await query.getDocuments(source: .server)
      return try snapshot.documents.first?.data(as: Memo.self)
    } catch {
      throw FirestoreRepositoryError.readFailed(underlying: error)
    }
  }

  public func fetchLegacyTodoCount(userId: String) async throws -> Int {
    let query = reference.todoCollection()
      .whereField("owner", isEqualTo: userId)

    do {
      let snapshot = try await query.count.getAggregation(source: .server)
      return Int(truncating: snapshot.count)
    } catch {
      throw FirestoreRepositoryError.readFailed(underlying: error)
    }
  }
}
