//
//  NetworkController.swift
//  TodoMate
//
//  Protocol for controlling remote network state.
//
//  Created by hs on 1/6/26.
//

import Foundation
// MARK: - Protocol

protocol NetworkController {
  func enableNetwork() async throws
  func disableNetwork() async throws
}

// MARK: - Mock Implementation

final class StubNetworkController: NetworkController {
  func enableNetwork() async throws { /* no-op */ }
  func disableNetwork() async throws { /* no-op */ }
}
