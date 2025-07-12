//
//  TodoRepository.swift
//  Todo
//

import FirebaseFirestore
import Foundation

// MARK: - FirestoreTodoRepository

final class FirestoreTodoRepository: TodoRepository {
  private let reference: FirestoreReference

  init(reference: FirestoreReference = .shared) {
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

  func observeAll(query: TodoQuery) -> AsyncStream<RepositoryEvent<Todo>> {
    let firestoreQuery = buildFirestoreQuery(from: query)

    return AsyncStream { continuation in
      let listener = firestoreQuery.addSnapshotListener { snapshot, error in
        if let error { continuation.yield(.error(error)); return }
        guard let snapshot else { continuation.yield(.error(FirestoreRepositoryError.snapshotNotFound)); return }

        for change in snapshot.documentChanges {
          guard let todo = try? change.document.data(as: Todo.self) else {
            continuation.yield(.error(FirestoreRepositoryError.decodingError(documentID: change.document.documentID)))
            continue
          }
          switch change.type {
          case .added: continuation.yield(.added(todo))
          case .modified: continuation.yield(.modified(todo))
          case .removed: continuation.yield(.removed(todo))
          @unknown default: continuation.yield(.error(FirestoreRepositoryError.unknownChangeType))
          }
        }
      }
      continuation.onTermination = { @Sendable _ in listener.remove() }
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
        firestoreQuery = firestoreQuery.whereField("date", isGreaterThanOrEqualTo: range.lowerBound).whereField("date", isLessThanOrEqualTo: range.upperBound)
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
  func observeAll(query _: TodoQuery) -> AsyncStream<RepositoryEvent<Todo>> { AsyncStream { $0.finish() } }
}
