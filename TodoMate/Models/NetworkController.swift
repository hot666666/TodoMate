//
//  NetworkController.swift
//  TodoMate
//
//  Protocol for controlling Firestore network state.
//  Allows dependency injection for testing and previews.
//
//  Created by hs on 1/6/26.
//

import Foundation

// MARK: - Protocol

protocol NetworkController {
  func enableNetwork() async throws
  func disableNetwork() async throws
}

// MARK: - Firestore Implementation

final class FirestoreNetworkController: NetworkController {
  private let reference: FirestoreReference

  init(reference: FirestoreReference = .shared) {
    self.reference = reference
  }

  func enableNetwork() async throws {
    try await reference.db.enableNetwork()
  }

  func disableNetwork() async throws {
    try await reference.db.disableNetwork()
  }
}

// MARK: - Stub for Previews/Tests

final class StubNetworkController: NetworkController {
  func enableNetwork() async throws { /* no-op */ }
  func disableNetwork() async throws { /* no-op */ }
}
