//
//  AuthService.swift
//  TodoMate
//
//  Created by hs on 7/12/25.
//

public protocol AuthService: Sendable {
  var signedInUserId: String? { get }
  func signIn() async throws
  func signOut() throws
  func listenToAuthStateChanges() -> AsyncStream<String?>
}

// MARK: - StubAuthService

public final class StubAuthService: AuthService, Sendable {
  private let userId: String?

  public init(signedInUserId: String? = User.local.id) {
    userId = signedInUserId
  }

  public var signedInUserId: String? {
    userId
  }

  public func signIn() async throws {}
  public func signOut() throws {}
  public func listenToAuthStateChanges() -> AsyncStream<String?> {
    AsyncStream { continuation in
      continuation.yield(userId)
    }
  }
}
