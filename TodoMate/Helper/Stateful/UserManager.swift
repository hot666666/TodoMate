//
//  UserManager.swift
//  TodoMate
//
//  Created by hs on 8/15/24.
//

import SwiftUI

@Observable
class UserManager: UserManagerType {
    private let userRepository: UserRepositoryType
    
    var users: [User] = []
    
    init(userRepository: UserRepositoryType = FirestoreUserRepository(reference: .shared)) {
        self.userRepository = userRepository
    }
}

extension UserManager {
    @MainActor
    func fetch() async {
        print("[Fetching User] -")
        do {
            users = try await userRepository.fetchAllUsers().map { $0.toModel() }
        } catch {
            print("Error fetching users: \(error)")
        }
    }
    
    func update(_ user: User) {
        print("[Updating User] - \(user)")
        Task {
            do {
                try await userRepository.updateUser(user: user.toDTO())
            } catch {
                print("Error updating users: \(error)")
            }
        }
    }
}
