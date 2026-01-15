//
//  ConnectivityRepositoryImpl.swift
//  TodoMate
//
//  Created by agent on 1/12/26.
//

import FirebaseFirestore
import TodoMateDomain

public final class FirestoreConnectivityRepository: ConnectivityRepository {
  private let reference: FirestoreReference

  public init(reference: FirestoreReference) {
    self.reference = reference
  }

  public func setNetworkEnabled(_ isEnabled: Bool) async throws {
    do {
      if isEnabled {
        try await reference.db.enableNetwork()
      } else {
        try await reference.db.disableNetwork()
      }
    } catch {
      throw FirestoreRepositoryError.networkOperationFailed(underlying: error)
    }
  }
}
