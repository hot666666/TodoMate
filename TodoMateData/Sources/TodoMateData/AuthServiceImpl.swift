//
//  AuthServiceImpl.swift
//  Todo
//
//  Created by hs on 6/3/25.
//

@preconcurrency import FirebaseAuth
import GoogleSignIn
import TodoMateDomain

public final class FirebaseAuthService: AuthService {
  public var signedInUserId: String? {
    Auth.auth().currentUser?.uid
  }

  public init() {}

  @MainActor
  public func signIn() async throws {
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

  public func signOut() throws {
    try Auth.auth().signOut()
    GIDSignIn.sharedInstance.signOut()
    Task { @MainActor in
      try? await FirestoreReference.shared.clearPersistence()
    }
  }

  public func listenToAuthStateChanges() -> AsyncStream<String?> {
    AsyncStream { continuation in
      let authHandle = Auth.auth().addStateDidChangeListener { _, firebaseUser in
        continuation.yield(firebaseUser?.uid)
      }

      // MARK: - 아직 ListenerRegistration가 Firebase 라이브러리 차원에서 Sendable 처리가 아직 되어있지 않음

      continuation.onTermination = { @Sendable _ in
        Auth.auth().removeStateDidChangeListener(authHandle)
      }
    }
  }
}

public enum AuthServiceError: Error {
  case noActiveWindowScene
  case userTokenNotFound
}
