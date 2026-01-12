//
//  ConnectivityRepositoryImpl.swift
//  TodoMate
//
//  Created by agent on 1/12/26.
//

import FirebaseFirestore

final class FirestoreConnectivityRepository: ConnectivityRepository {
  private let reference: FirestoreReference

  init(reference: FirestoreReference) {
    self.reference = reference
  }

  func setNetworkEnabled(_ isEnabled: Bool) async throws {
    if isEnabled {
      try await reference.db.enableNetwork()
    } else {
      try await reference.db.disableNetwork()
    }
  }
}

// MARK: - StubConnectivityRepository

final class StubConnectivityRepository: ConnectivityRepository {
  func setNetworkEnabled(_: Bool) async throws {}
}
