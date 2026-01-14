//
//  MessageRepositoryImpl.swift
//  Todo
//
//  Created by hs on 6/9/25.
//

@preconcurrency import FirebaseFirestore
import TodoMateDomain

public final class FirestoreMessageRepository: MessageRepository {
  private let reference: FirestoreReference

  public init(reference: FirestoreReference) {
    self.reference = reference
  }

  public func create(_ message: GroupMessage) throws {
    try reference.messageCollection().document(message.id).setData(from: message)
  }

  public func update(_ message: GroupMessage) throws {
    try reference.messageCollection().document(message.id).setData(from: message)
  }

  public func delete(_ messageId: String) async throws {
    try await reference.messageCollection().document(messageId).delete()
  }

  public func readAll(groupId: String, source: DataSource) async throws -> [GroupMessage] {
    let snapshot = try await reference.messageCollection()
      .whereField("groupId", isEqualTo: groupId)
      .order(by: "createdAt", descending: false)
      .getDocuments(source: source.firestoreSource)
    return snapshot.documents.compactMap { try? $0.data(as: GroupMessage.self) }
  }

  public func observeAll(groupId: String) -> AsyncStream<RepositoryEvent<GroupMessage>> {
    AsyncStream { continuation in
      let listener = reference.messageCollection()
        .whereField("groupId", isEqualTo: groupId)
        .order(by: "createdAt", descending: false)
        .addSnapshotListener { snapshot, error in
          if let error {
            continuation.yield(.error(error))
            return
          }
          guard let snapshot else {
            continuation.yield(.error(FirestoreRepositoryError.snapshotNotFound))
            return
          }

          for change in snapshot.documentChanges {
            guard let message = try? change.document.data(as: GroupMessage.self) else {
              continuation.yield(
                .error(
                  FirestoreRepositoryError.decodingError(documentID: change.document.documentID)))
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

      // NOTE: Firebase의 ListenerRegistration이 아직 Sendable을 준수하지 않음
      continuation.onTermination = { @Sendable _ in listener.remove() }
    }
  }
}

public enum FirestoreRepositoryError: Error {
  case snapshotNotFound
  case decodingError(documentID: String)
  case unknownChangeType
}
