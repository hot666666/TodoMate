//
//  UserRepository.swift
//  TodoMate
//
//  Created by hs on 8/15/24.
//

import Foundation

protocol UserRepositoryType {
    func fetchUser(id: String) async throws -> UserDTO
    func fetchAllUsers() async throws -> [UserDTO]
    func updateUser(user: UserDTO) async throws
    func deleteUser(id: String) async throws
}

final class FirestoreUserRepository: UserRepositoryType {
    private let reference: FirestoreReference
    
    init(reference: FirestoreReference = .shared) {
        self.reference = reference
    }
}
#if !PREVIEW
extension FirestoreUserRepository {
    func fetchUser(id: String) async throws -> UserDTO {
        let docRef = reference.userCollection().document(id)
        let snapshot = try await docRef.getDocument()
        
        guard let user = try? snapshot.data(as: UserDTO.self) else {
            throw NSError(domain: "FirestoreUserRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to decode User"])
        }
        
        return user
    }
    
    func fetchAllUsers() async throws -> [UserDTO] {
        let snapshot = try await reference.userCollection().getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: UserDTO.self) }
    }
    
    func updateUser(user: UserDTO) async throws {
        // 없으면 생성, 있으면 업데이트
        guard let userId = user.id else {
            throw NSError(domain: "FirestoreUserRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "User ID is missing"])
        }
        let userRef = reference.userCollection().document(userId)
        try userRef.setData(from: user)
    }
    
    func deleteUser(id: String) async throws {
        let userRef = reference.userCollection().document(id)
        try await userRef.delete()
    }
}
#else
extension FirestoreUserRepository {
    func fetchUser(id: String) async throws -> UserDTO {
        return UserDTO.stub[0]
    }
    
    func fetchAllUsers() async throws -> [UserDTO] {
        return UserDTO.stub
    }
    
    func updateUser(user: UserDTO) async throws {
        print("[Updating User] - \(user)")
    }
    
    func deleteUser(id: String) async throws {
        print("[Deleting User] - \(id)")
    }
}
#endif
