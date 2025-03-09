//
//  AuthManager.swift
//  TodoMate
//
//  Created by hs on 1/19/25.
//

import SwiftUI

final class AuthService: AuthServiceType {
    private let userService: UserServiceType
    private let googleSignInService: GoogleSignInServiceType
    
    init(userService: UserServiceType, googleSignInService: GoogleSignInServiceType) {
        self.userService = userService
        self.googleSignInService = googleSignInService
    }
    
    func signIn() async throws -> User {
        let gUser = try await googleSignInService.signIn()
        
        guard let existingUser = await userService.fetch(uid: gUser.uid) else {
            let newUser = User(uid: gUser.uid, nickname: gUser.name ?? "Unknown")
            
            await userService.update(newUser)
            print("[AuthService] Created new user: \(newUser.uid)")
            return newUser
        }
        
        print("[AuthService] User already exists with uid: \(existingUser.uid)")
        return existingUser
    }
    
    func signOut() async {
        googleSignInService.signOut()
    }
}
    

