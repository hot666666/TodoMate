//
//  AuthServiceImpl.swift
//  Todo
//
//  Created by hs on 6/3/25.
//

import FirebaseAuth
import GoogleSignIn

final class FirebaseAuthService: AuthService {
  var signedInUserId: String? {
    Auth.auth().currentUser?.uid
  }

  @MainActor
  func signIn() async throws {
    let signInResult: GIDSignInResult

    #if os(macOS)
      guard let window = NSApplication.shared.windows.first else {
        throw AuthServiceError.noActiveWindowScene
      }
      signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)
    #elseif os(iOS)
      guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first,
            let rootVC = window.rootViewController
      else {
        throw AuthServiceError.noActiveWindowScene
      }
      signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
    #endif

    guard let idToken = signInResult.user.idToken?.tokenString else {
      throw AuthServiceError.userTokenNotFound
    }
    let accessToken = signInResult.user.accessToken.tokenString
    let credential = GoogleAuthProvider.credential(
      withIDToken: idToken,
      accessToken: accessToken,
    )

    try await Auth.auth().signIn(with: credential)
  }

  func signOut() throws {
    try Auth.auth().signOut()
    GIDSignIn.sharedInstance.signOut()
  }

  func listenToAuthStateChanges() -> AsyncStream<String?> {
    AsyncStream { continuation in
      let authHandle = Auth.auth().addStateDidChangeListener { _, firebaseUser in
        continuation.yield(firebaseUser?.uid)
      }

      continuation.onTermination = { @Sendable _ in
        Auth.auth().removeStateDidChangeListener(authHandle)
      }
    }
  }
}

final class StubAuthService: AuthService {
  var signedInUserId: String? {
    User.stub.id
  }

  func signIn() async throws {}

  func signOut() throws {}

  func listenToAuthStateChanges() -> AsyncStream<String?> {
    AsyncStream { continuation in
      continuation.yield(User.stub.id)
      continuation.finish()
    }
  }
}
