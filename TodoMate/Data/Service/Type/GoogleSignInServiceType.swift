//
//  GoogleSignInServiceType.swift
//  TodoMate
//
//  Created by hs on 3/6/25.
//


protocol GoogleSignInServiceType {
    func signIn() async throws -> GoogleUser
    func signOut()
}

class StubGoogleSignInService: GoogleSignInServiceType {
    func signIn() async throws -> GoogleUser {
        print("Sign in in StubGoogleSignInService")
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        return GoogleUser(uid: "stub", name: "Stub User", token: "stub")
    }
    
    func signOut() {
        print("Sign out in StubGoogleSignInService")
    }
}