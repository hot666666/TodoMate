//
//  UserService.swift
//  TodoMate
//
//  Created by hs on 12/28/24.
//

final class UserService: UserServiceType {
    private let userRepository: UserRepositoryType
    
    init(userRepository: UserRepositoryType = FirestoreUserRepository(reference: .shared)) {
        self.userRepository = userRepository
    }
    
    func fetch() async -> [User] {
        print("[Fetching Users] -")
        do {
            return try await userRepository.fetchAllUsers().map { $0.toModel() }
        } catch {
            print("Error fetching users: \(error)")
        }
        return []
    }
    
    func fetch(uid: String) async -> User? {
        print("[Fetching User] - \(uid)")
        return try? await userRepository.fetchUser(id: uid).toModel()
    }
    
    func update(_ user: User) async {
        print("[Updating User] - \(user)")
        do {
            try await userRepository.updateUser(user: user.toDTO())
        } catch {
            print("Error updating users: \(error)")
        }
    }
}


