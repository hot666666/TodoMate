//
//  FirestoreUserRepository.swift
//  TodoMate
//
//  Created by hs on 8/15/24.
//

import Foundation

enum UserRepositoryError: Error {
  case decodingError
  case missingUserId
}

protocol UserRepositoryType {
  func createOrUpdate(user: UserDTO) async throws
  func read(id: String) async throws -> UserDTO
  func readAll() async throws -> [UserDTO]
  func readAll(gid: String) async throws -> [UserDTO]
  func delete(id: String) async throws
}

final class FirestoreUserRepository: UserRepositoryType {
  private let reference: FirestoreReference

  init(reference: FirestoreReference = .shared) {
    self.reference = reference
  }
}

#if !PREVIEW
  extension FirestoreUserRepository {
    func read(id: String) async throws -> UserDTO {
      let docRef = reference.userCollection().document(id)
      let snapshot = try await docRef.getDocument()

      do {
        return try snapshot.data(as: UserDTO.self)
      } catch {
        throw UserRepositoryError.decodingError
      }
    }

    func readAll() async throws -> [UserDTO] {
      let snapshot = try await reference.userCollection().getDocuments()
      return snapshot.documents.compactMap { try? $0.data(as: UserDTO.self) }
    }

    func readAll(gid: String) async throws -> [UserDTO] {
      let snapshot = try await reference.userCollection()
        .whereField("gid", isEqualTo: gid)
        .getDocuments()
      return snapshot.documents.compactMap { try? $0.data(as: UserDTO.self) }
    }

    // TODO: - remove async
    func createOrUpdate(user: UserDTO) async throws {
      // create -> ouath로 생성된 uid를 사용
      // update -> uid를 사용
      guard let userId = user.id else {
        throw UserRepositoryError.missingUserId
      }

      let userRef = reference.userCollection().document(userId)
      try userRef.setData(from: user)
    }

    func delete(id: String) async throws {
      let userRef = reference.userCollection().document(id)
      try await userRef.delete()
    }
  }
#else
  extension FirestoreUserRepository {
    func read(id: String) async throws -> UserDTO {
      return UserDTO.stub[0]
    }

    func readAll() async throws -> [UserDTO] {
      return UserDTO.stub
    }

    func readAll(gid: String) async throws -> [UserDTO] {
      return UserDTO.stub
    }

    func createOrUpdate(user: UserDTO) async throws {
      print("[Updating User] - \(user)")
    }

    func delete(id: String) async throws {
      print("[Deleting User] - \(id)")
    }
  }
#endif
