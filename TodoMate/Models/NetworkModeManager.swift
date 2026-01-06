//
//  NetworkModeManager.swift
//  TodoMate
//
//  Manages Firestore network mode (online/offline).
//  Uses Firestore's built-in disableNetwork/enableNetwork APIs.
//
//  Created by hs on 1/5/26.
//

import Foundation

@Observable
@MainActor
final class NetworkModeManager {
  @ObservationIgnored private let userDefaults: UserDefaults
  @ObservationIgnored private let networkController: NetworkController

  // MARK: - State

  private(set) var isOnline: Bool = true
  private(set) var isTransitioning: Bool = false

  init(container: DIContainer) {
    userDefaults = container.userDefaults
    networkController = container.networkController

    // Load saved preference (default: online)
    isOnline = userDefaults.bool(for: .networkModeIsOnline, default: true)

    // Apply saved state on init
    Task {
      await applyNetworkState()
    }
  }

  // MARK: - Public Methods

  /// Toggle network mode between online and offline
  func toggle() async {
    await setOnline(!isOnline)
  }

  /// Explicitly set network mode
  func setOnline(_ online: Bool) async {
    guard !isTransitioning else { return }

    // UI
    defer { isTransitioning = false }
    isTransitioning = true
    isOnline = online

    // User Defaults
    userDefaults.set(online, for: .networkModeIsOnline)

    // Firestore
    await applyNetworkState()
  }

  // MARK: - Private Methods

  private func applyNetworkState() async {
    do {
      if isOnline {
        try await networkController.enableNetwork()
        Log.info("Network enabled", category: .network)
      } else {
        try await networkController.disableNetwork()
        Log.info("Network disabled (offline mode)", category: .network)
      }
    } catch {
      Log.error("Failed to change network state: \(error)", category: .network)
    }
  }
}

extension NetworkModeManager {
  static let preview = NetworkModeManager(container: .preview)
}
