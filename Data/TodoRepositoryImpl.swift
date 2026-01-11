//
//  TodoRepositoryImpl.swift
//  Todo
//

import FirebaseFirestore
import Foundation

final class FirestoreTodoRepository: TodoRepository {
  private let reference: FirestoreReference

  init(reference: FirestoreReference) {
    self.reference = reference
  }

  func create(_ todo: Todo) throws {
    try reference.todoCollection().document(todo.id).setData(from: todo)
  }

  func update(_ todo: Todo) throws {
    try reference.todoCollection().document(todo.id).setData(from: todo)
  }

  func delete(_ todoId: String) async throws {
    try await reference.todoCollection().document(todoId).delete()
  }

  func readAll(query: TodoQuery, source: DataSource) async throws -> [Todo] {
    let firestoreQuery = buildFirestoreQuery(from: query)
    let snapshot = try await firestoreQuery.getDocuments(source: source.firestoreSource)
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

// MARK: - StubTodoRepository

final class StubTodoRepository: TodoRepository {
  func create(_: Todo) throws {}
  func update(_: Todo) throws {}
  func delete(_: String) async throws {}
  func readAll(query _: TodoQuery, source _: DataSource) async throws -> [Todo] { [] }
}
