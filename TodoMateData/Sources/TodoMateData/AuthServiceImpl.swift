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
      do {
        signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)
      } catch {
        throw AuthServiceError.signInFailed(underlying: error)
      }
    #elseif os(iOS)
      guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first,
            let rootVC = window.rootViewController
      else {
        throw AuthServiceError.noActiveWindowScene
      }
      do {
        signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
      } catch {
        throw AuthServiceError.signInFailed(underlying: error)
      }
    #endif

    guard let idToken = signInResult.user.idToken?.tokenString else {
      throw AuthServiceError.userTokenNotFound
    }
    let accessToken = signInResult.user.accessToken.tokenString
    let credential = GoogleAuthProvider.credential(
      withIDToken: idToken,
      accessToken: accessToken,
    )

    do {
      try await Auth.auth().signIn(with: credential)
    } catch {
      throw AuthServiceError.signInFailed(underlying: error)
    }
  }

  public func signOut() throws {
    do {
      try Auth.auth().signOut()
      GIDSignIn.sharedInstance.signOut()
      Task { @MainActor in
        try? await FirestoreReference.shared.clearPersistence()
      }
    } catch {
      throw AuthServiceError.signOutFailed(underlying: error)
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
