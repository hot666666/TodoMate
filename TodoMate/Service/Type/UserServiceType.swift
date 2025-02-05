//
//  StubUserService.swift
//  TodoMate
//
//  Created by hs on 2/5/25.
//

protocol UserServiceType {
    func fetch() async -> [User]
    func fetch(uid: String) async -> User?
    func update(_ user: User) async
}

class StubUserService: UserServiceType {
    func fetch() async -> [User] {
        print("[Fetching Users] - \(User.stub.count)")
        return User.stub
    }
    
    func fetch(uid: String) async -> User? {
        return User.stub.first
    }
    
    func update(_ user: User) {
        print("[Updating User] - \(user)")
    }
}
