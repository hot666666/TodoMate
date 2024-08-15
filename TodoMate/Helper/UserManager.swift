//
//  UserManager.swift
//  TodoMate
//
//  Created by hs on 8/15/24.
//

import SwiftUI

protocol UserManagerProtocol {
//    func create(_ user: Todo) async
    func fetch() async
//    func remove(_ todo: Todo)
    func update(_ user: User)
}

@Observable
class UserManager: UserManagerProtocol {
    private let userRepository: UserRepository
    
    var users: [User] = []
    
    init(userRepository: UserRepository = FirestoreUserRepository(reference: .shared)) {
        self.userRepository = userRepository
    }
}

extension UserManager {
    @MainActor
    func fetch() async {
        do {
            users = try await userRepository.fetchAllUsers().map { $0.toModel() }
        } catch {
            print("Error fetching users: \(error)")
        }
    }
    
    func update(_ user: User) {
        Task {
            do {
                try await userRepository.updateUser(user: user.toDTO())
            } catch {
                print("Error updating users: \(error)")
            }
        }
    }
}

extension UserManager {
    func createUser(user: User) async throws {
        let createdId = try await userRepository.createUser(user: user.toDTO())
        // TODO: - user.id = createdId
    }
    
    func deleteUser(id: String) async throws {
        try await userRepository.deleteUser(id: id)
    }
}
