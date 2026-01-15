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
    do {
      try await reference.userCollection().document(newUser.id).setData(from: newUser)
      return newUser
    } catch {
      throw FirestoreRepositoryError.createFailed(underlying: error)
    }
  }

  public func read(userId: String, useCache: Bool) async throws -> User? {
    let source: FirestoreSource = useCache ? .cache : .default
    do {
      let snapshot = try await reference.userCollection().document(userId).getDocument(
        source: source)
      return try? snapshot.data(as: User.self)
    } catch {
      throw FirestoreRepositoryError.readFailed(underlying: error)
    }
  }

  public func readAll(groupId: String, useCache: Bool) async throws -> [User] {
    let source: FirestoreSource = useCache ? .cache : .default
    do {
      let snapshot = try await reference.userCollection().whereField("groupId", isEqualTo: groupId)
        .getDocuments(source: source)
      return snapshot.documents.compactMap { try? $0.data(as: User.self) }
    } catch {
      throw FirestoreRepositoryError.readFailed(underlying: error)
    }
  }

  public func readAll(useCache: Bool) async throws -> [User] {
    let source: FirestoreSource = useCache ? .cache : .default
    do {
      let snapshot = try await reference.userCollection().getDocuments(source: source)
      return snapshot.documents.compactMap { try? $0.data(as: User.self) }
    } catch {
      throw FirestoreRepositoryError.readFailed(underlying: error)
    }
  }

  public func update(_ user: User) async throws {
    do {
      try reference.userCollection().document(user.id).setData(from: user, merge: true)
    } catch {
      throw FirestoreRepositoryError.updateFailed(underlying: error)
    }
  }
}
