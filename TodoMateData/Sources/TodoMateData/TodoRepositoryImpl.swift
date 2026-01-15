//
//  TodoRepositoryImpl.swift
//  Todo
//

import FirebaseFirestore
import Foundation
import TodoMateDomain

public final class FirestoreTodoRepository: TodoRepository {
  private let reference: FirestoreReference

  public init(reference: FirestoreReference) {
    self.reference = reference
  }

  public func create(_ todo: Todo) async throws {
    try reference.todoCollection().document(todo.id).setData(from: todo)
  }

  public func update(_ todo: Todo) async throws {
    try reference.todoCollection().document(todo.id).setData(from: todo)
  }

  public func delete(_ todoId: String) async throws {
    try await reference.todoCollection().document(todoId).delete()
  }

  public func readAll(query: TodoQuery, useCache: Bool) async throws -> [Todo] {
    let firestoreQuery = buildFirestoreQuery(from: query)
    let source: FirestoreSource = useCache ? .cache : .default
    let snapshot = try await firestoreQuery.getDocuments(source: source)
    return snapshot.documents.compactMap { try? $0.data(as: Todo.self) }
  }

  private func buildFirestoreQuery(from todoQuery: TodoQuery) -> Query {
    var firestoreQuery: Query = reference.todoCollection()

    for filter in todoQuery.filters {
      switch filter {
      case let .owner(userId):
        firestoreQuery = firestoreQuery.whereField("owner", isEqualTo: userId)
      case let .owners(userIds):
        if !userIds.isEmpty { firestoreQuery = firestoreQuery.whereField("owner", in: userIds) }
      case let .dateRange(range):
        firestoreQuery = firestoreQuery.whereField("date", isGreaterThanOrEqualTo: range.lowerBound)
          .whereField("date", isLessThanOrEqualTo: range.upperBound)
      case let .status(status):
        firestoreQuery = firestoreQuery.whereField("status", isEqualTo: status.rawValue)
      }
    }
    return firestoreQuery
  }
}
