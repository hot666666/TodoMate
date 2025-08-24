//
//  MessageRepositoryImpl.swift
//  Todo
//
//  Created by hs on 6/9/25.
//

import FirebaseFirestore

final class FirestoreMessageRepository: MessageRepository {
  private let reference: FirestoreReference

  init(reference: FirestoreReference = .shared) {
    self.reference = reference
  }

  func create(_ message: GroupMessage) throws {
    try reference.messageCollection().document(message.id).setData(from: message)
  }

  func update(_ message: GroupMessage) throws {
    try reference.messageCollection().document(message.id).setData(from: message)
  }

  func delete(_ messageId: String) async throws {
    try await reference.messageCollection().document(messageId).delete()
  }

  func readAll(groupId: String, source: DataSource) async throws -> [GroupMessage] {
    let snapshot = try await reference.messageCollection()
      .whereField("groupId", isEqualTo: groupId)
      .order(by: "createdAt", descending: false)
      .getDocuments(source: source.firestoreSource)
    return snapshot.documents.compactMap { try? $0.data(as: GroupMessage.self) }
  }

  func observeAll(groupId: String) -> AsyncStream<RepositoryEvent<GroupMessage>> {
    AsyncStream { continuation in
      let listener = reference.messageCollection()
        .whereField("groupId", isEqualTo: groupId)
        .addSnapshotListener { snapshot, error in
          if let error { continuation.yield(.error(error)); return }
          guard let snapshot else { continuation.yield(.error(FirestoreRepositoryError.snapshotNotFound)); return }

          for change in snapshot.documentChanges {
            guard let message = try? change.document.data(as: GroupMessage.self) else {
              continuation.yield(.error(FirestoreRepositoryError.decodingError(documentID: change.document.documentID)))
              continue
            }
            switch change.type {
            case .added: continuation.yield(.added(message))
            case .modified: continuation.yield(.modified(message))
            case .removed: continuation.yield(.removed(message))
            @unknown default: continuation.yield(.error(FirestoreRepositoryError.unknownChangeType))
            }
          }
        }
      continuation.onTermination = { @Sendable _ in listener.remove() }
    }
  }
}

final class StubMessageRepository: MessageRepository {
  func create(_: GroupMessage) throws {}
  func update(_: GroupMessage) throws {}
  func delete(_: String) async throws {}
  func readAll(groupId _: String, source _: DataSource) async throws -> [GroupMessage] { [] }
  func observeAll(groupId _: String) -> AsyncStream<RepositoryEvent<GroupMessage>> { AsyncStream { $0.finish() } }
}
