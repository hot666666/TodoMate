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

  // MARK: - State

  private(set) var isOnline: Bool = true
  private(set) var isTransitioning: Bool = false

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults

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
    let ref = FirestoreReference.shared
    do {
      if isOnline {
        try await ref.db.enableNetwork()
        print("[NetworkModeManager] - Network enabled")
      } else {
        try await ref.db.disableNetwork()
        print("[NetworkModeManager] - Network disabled (offline mode)")
      }
    } catch {
      print("[NetworkModeManager] - Failed to change network state: \(error)")
    }
  }
}
