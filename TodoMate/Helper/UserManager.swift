//
//  UserManager.swift
//  TodoMate
//
//  Created by hs on 8/15/24.
//

import SwiftUI

protocol UserManagerProtocol {
    var users: [User] { get }
    func fetch() async
    func update(_ user: User)
    // TODO: - 추가기능
    ///    func create(_ user: Todo) async
    ///    func remove(_ todo: Todo)
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

class StubUserManager: UserManagerProtocol {
    var users: [User] = []
    
    @MainActor
    func fetch() async {
        users = User.stub
    }
    
    func update(_ user: User) {
        if let updatedUser = users.first(where: { $0.fid == user.fid }) {
            updatedUser.name = user.name
        }
    }
}
