//
//  UserRepository.swift
//  Todo
//
//  Created by hs on 6/3/25.
//

import FirebaseFirestore

final class FirestoreUserRepository: UserRepository {
  private let reference: FirestoreReference

  init(reference: FirestoreReference = .shared) {
    self.reference = reference
  }

  func create(_ newUser: User) throws -> User {
    try reference.userCollection().document(newUser.id).setData(from: newUser)
    return newUser
  }

  func read(userId: String, source: DataSource) async throws -> User? {
    let snapshot = try await reference.userCollection().document(userId).getDocument(source: source.firestoreSource)
    return try? snapshot.data(as: User.self)
  }

  func readAll(groupId: String, source: DataSource) async throws -> [User] {
    let snapshot = try await reference.userCollection().whereField("groupId", isEqualTo: groupId).getDocuments(source: source.firestoreSource)
    return snapshot.documents.compactMap { try? $0.data(as: User.self) }
  }

  func readAll(source: DataSource) async throws -> [User] {
    let snapshot = try await reference.userCollection().getDocuments(source: source.firestoreSource)
    return snapshot.documents.compactMap { try? $0.data(as: User.self) }
  }
}

final class StubUserRepository: UserRepository {
  func create(_ newUser: User) throws -> User { newUser }
  func read(userId _: String, source _: DataSource) async throws -> User? { User.stub }
  func readAll(groupId _: String, source _: DataSource) async throws -> [User] { User.stubs }
  func readAll(source _: DataSource) async throws -> [User] { User.stubs }
}
