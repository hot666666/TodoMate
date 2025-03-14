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

enum GoogleSignInServiceError: Error {
	case invalidAppConfiguration
	case noActiveWindowScene
	case failedToGetToken
	case failedToGetUserID
}

class GoogleSignInService: GoogleSignInServiceType {
	@MainActor
	func signIn() async throws -> GoogleUser {
		try? Auth.auth().signOut()
		do {
			guard let clientId = FirebaseApp.app()?.options.clientID else {
				print("Error: Invalid app configuration")
				throw GoogleSignInServiceError.invalidAppConfiguration
			}
			
			let configuration = GIDConfiguration(clientID: clientId)
			GIDSignIn.sharedInstance.configuration = configuration
			
			guard let windowScene = NSApplication.shared.windows.first else {
				print("Error: No active window scene found")
				throw GoogleSignInServiceError.noActiveWindowScene
			}
			let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: windowScene)
			
			guard let idToken = result.user.idToken?.tokenString else {
				print("Error: Failed to get authentication token")
				throw GoogleSignInServiceError.failedToGetToken
			}
			
			let credential = GoogleAuthProvider.credential(
				withIDToken: idToken,
				accessToken: result.user.accessToken.tokenString
			)
			
			let authResult = try await Auth.auth().signIn(with: credential)
			let user = authResult.user
			
			guard !user.uid.isEmpty else {
				print("Error: Failed to get user ID")
				throw GoogleSignInServiceError.failedToGetUserID
			}
			
			
			print("Sign in successful in GoogleSignInService")
			return GoogleUser(uid: user.uid, name: user.displayName, token: idToken)
		}
	}
	
	func signOut() {
		GIDSignIn.sharedInstance.signOut()
	}
}
