//
//  AuthServiceType.swift
//  TodoMate
//
//  Created by hs on 3/6/25.
//

protocol AuthServiceType {
    func signIn() async throws -> User
    func signOut() async
}

final class StubAuthService: AuthServiceType {
    func signIn() async throws -> User {
        return User.stub[0]
    }
    
    func signOut() async {}
}
