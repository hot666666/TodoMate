//
//  UserRepository.swift
//  TodoMate
//
//  Created by hs on 8/15/24.
//

import Foundation

protocol UserRepository {
    func fetchUser(id: String) async throws -> UserDTO
    func fetchAllUsers() async throws -> [UserDTO]
    func createUser(user: UserDTO) async throws -> String
    func updateUser(user: UserDTO) async throws
    func deleteUser(id: String) async throws
}

class FirestoreUserRepository: UserRepository {
    private let reference: FirestoreReference
    
    init(reference: FirestoreReference = .shared) {
        self.reference = reference
    }
    
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
    
    func createUser(user: UserDTO) async throws -> String {
        let newUserRef = reference.userCollection().document()
        var newUser = user
        newUser.id = newUserRef.documentID
        try newUserRef.setData(from: newUser)
        return newUserRef.documentID
    }
    
    func updateUser(user: UserDTO) async throws {
        guard let userId = user.id else { throw NSError(domain: "FirestoreUserRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "User ID is missing"]) }
        let userRef = reference.userCollection().document(userId)
        try userRef.setData(from: user)
    }
    
    func deleteUser(id: String) async throws {
        let userRef = reference.userCollection().document(id)
        try await userRef.delete()
    }
}
