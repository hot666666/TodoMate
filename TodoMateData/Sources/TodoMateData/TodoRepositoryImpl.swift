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
    do {
      try reference.todoCollection().document(todo.id).setData(from: todo)
    } catch {
      throw FirestoreRepositoryError.createFailed(underlying: error)
    }
  }

  public func update(_ todo: Todo) async throws {
    do {
      try reference.todoCollection().document(todo.id).setData(from: todo)
    } catch {
      throw FirestoreRepositoryError.updateFailed(underlying: error)
    }
  }

  public func delete(_ todoId: String) async throws {
    do {
      try await reference.todoCollection().document(todoId).delete()
    } catch {
      throw FirestoreRepositoryError.deleteFailed(underlying: error)
    }
  }

  public func read(id: String) async throws -> Todo? {
    do {
      let document = try await reference.todoCollection().document(id).getDocument()
      return try? document.data(as: Todo.self)
    } catch {
      throw FirestoreRepositoryError.readFailed(underlying: error)
    }
  }

  public func readAll(query: TodoQuery, useCache: Bool) async throws -> [Todo] {
    let firestoreQuery = buildFirestoreQuery(from: query)
    let source: FirestoreSource = useCache ? .cache : .default
    do {
      let snapshot = try await firestoreQuery.getDocuments(source: source)
      return snapshot.documents.compactMap { try? $0.data(as: Todo.self) }
    } catch {
      throw FirestoreRepositoryError.readFailed(underlying: error)
    }
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
