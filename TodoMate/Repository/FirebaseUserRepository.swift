//
//  FirebaseUserRepository.swift
//  TodoMate
//
//  Created by hs on 8/15/24.
//

import Foundation
import Firebase

protocol UserRepositoryType {
    func createUser(user: UserDTO) async throws -> String
    func fetchUser(id: String) async throws -> UserDTO
    func fetchAllUsers() async throws -> [UserDTO]
    func updateUser(user: UserDTO) async throws
    func deleteUser(id: String) async throws
}

class FirebaseUserRepository: UserRepositoryType {
    private let reference: FirebaseDatabaseReference
    
    init(reference: FirebaseDatabaseReference = .shared) {
        self.reference = reference
    }
}

extension FirebaseUserRepository {
    func createUser(user: UserDTO) async throws -> String {
        let newUserRef = reference.userReference().childByAutoId()
        var newUser = user
        newUser.id = newUserRef.key
        do {
            try await newUserRef.setValue(newUser)
            return newUserRef.key ?? ""
        } catch {
            throw FirebaseRepositoryError.setValueError
        }
    }
    
    func fetchUser(id: String) async throws -> UserDTO {
        do {
            let snapshot = try await reference.userReference().child(id).getData()
            guard snapshot.exists() else {
                throw FirebaseRepositoryError.invalidSnapshotError
            }
            
            let user = try reference.decode(from: snapshot, type: UserDTO.self)
            return user
        } catch {
            print("Error fetching user: \(error)")
            throw FirebaseRepositoryError.decodingError
        }
    }
    
    func fetchAllUsers() async throws -> [UserDTO] {
        do {
            let snapshot = try await reference.userReference().getData()
            guard snapshot.exists(), let children = snapshot.children.allObjects as? [DataSnapshot] else {
                throw FirebaseRepositoryError.invalidSnapshotError
            }
            
            let userDTOs = try children.map { child in
                try reference.decode(from: child, type: UserDTO.self)
            }
            
            if userDTOs.isEmpty {
                throw FirebaseRepositoryError.decodingError
            }
            
            return userDTOs
        } catch {
            print("Error fetching all users: \(error)")
            throw FirebaseRepositoryError.decodingError
        }
    }
    
    func updateUser(user: UserDTO) async throws {
        guard let userId = user.id else {
            throw NSError(domain: "FirebaseUserRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "User ID is missing"])
        }
        
        do {
            try await reference.userReference().child(userId).setValue(user)
        } catch {
            print("Error updating user: \(error)")
            throw FirebaseRepositoryError.setValueError
        }
    }
    
    func deleteUser(id: String) async throws {
        do {
            try await reference.userReference().child(id).removeValue()
        } catch {
            print("Error deleting user: \(error)")
            throw FirebaseRepositoryError.removeValueError
        }
    }
}
