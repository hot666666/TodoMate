//
//  GoogleSignInService.swift
//  TodoMate
//
//  Created by hs on 3/1/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

enum GoogleAuthError: Error {
    case invalidAppConfiguration
    case noActiveWindowScene
    case failedToGetToken
    case failedToGetUserID
}

protocol GoogleSignInServiceType {
    func signIn() async throws -> GoogleUser
    func signOut()
}

class GoogleSignInService: GoogleSignInServiceType {
    @MainActor
    func signIn() async throws -> GoogleUser {
        do {
            guard let clientId = FirebaseApp.app()?.options.clientID else {
                print("Error: Invalid app configuration")
                throw GoogleAuthError.invalidAppConfiguration
            }
            
            let configuration = GIDConfiguration(clientID: clientId)
            GIDSignIn.sharedInstance.configuration = configuration
            
            guard let windowScene = NSApplication.shared.windows.first else {
                print("Error: No active window scene found")
                throw GoogleAuthError.noActiveWindowScene
            }
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: windowScene)
            
            guard let idToken = result.user.idToken?.tokenString else {
                print("Error: Failed to get authentication token")
                throw GoogleAuthError.failedToGetToken
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            let user = authResult.user
            
            guard !user.uid.isEmpty else {
                print("Error: Failed to get user ID")
                throw GoogleAuthError.failedToGetUserID
            }
            
            
            print("Sign in successful in GoogleSignInService")
            return GoogleUser(uid: user.uid, name: user.displayName, token: idToken)
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }
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
