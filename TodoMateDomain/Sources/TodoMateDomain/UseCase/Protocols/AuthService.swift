//
//  AuthService.swift
//  TodoMate
//
//  Created by hs on 7/12/25.
//

public protocol AuthService {
  var signedInUserId: String? { get }
  func signIn() async throws
  func signOut() throws
  func listenToAuthStateChanges() -> AsyncStream<String?>
}
