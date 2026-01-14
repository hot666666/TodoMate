//
//  UserRepositoryImpl.swift
//  Todo
//
//  Created by hs on 6/3/25.
//

import FirebaseFirestore
import TodoMateDomain

public final class FirestoreUserRepository: UserRepository {
  private let reference: FirestoreReference

  public init(reference: FirestoreReference) {
    self.reference = reference
  }

  public func create(_ newUser: User) async throws -> User {
    try await reference.userCollection().document(newUser.id).setData(from: newUser)
    return newUser
  }

  public func read(userId: String, source: DataSource) async throws -> User? {
    let snapshot = try await reference.userCollection().document(userId).getDocument(
      source: source.firestoreSource)
    return try? snapshot.data(as: User.self)
  }

  public func readAll(groupId: String, source: DataSource) async throws -> [User] {
    let snapshot = try await reference.userCollection().whereField("groupId", isEqualTo: groupId)
      .getDocuments(source: source.firestoreSource)
    return snapshot.documents.compactMap { try? $0.data(as: User.self) }
  }

  public func readAll(source: DataSource) async throws -> [User] {
    let snapshot = try await reference.userCollection().getDocuments(source: source.firestoreSource)
    return snapshot.documents.compactMap { try? $0.data(as: User.self) }
  }

  public func update(_ user: User) async throws {
    try reference.userCollection().document(user.id).setData(from: user, merge: true)
  }
}
