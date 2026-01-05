//
//  NetworkModeManager.swift
//  TodoMate
//
//  Manages Firestore network mode (online/offline).
//  Uses Firestore's built-in disableNetwork/enableNetwork APIs.
//
//  Created by agent on 1/5/26.
//

import FirebaseFirestore
import Foundation

@Observable
@MainActor
final class NetworkModeManager {
  // MARK: - State

  private(set) var isOnline: Bool = true
  private(set) var isTransitioning: Bool = false

  // Persist user preference
  private let userDefaultsKey = "network_mode_is_online"

  init() {
    // Load saved preference (default: online)
    isOnline = UserDefaults.standard.object(forKey: userDefaultsKey) as? Bool ?? true

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

    isTransitioning = true
    isOnline = online

    // Save preference
    UserDefaults.standard.set(online, forKey: userDefaultsKey)

    await applyNetworkState()
    isTransitioning = false
  }

  // MARK: - Private Methods

  private func applyNetworkState() async {
    do {
      if isOnline {
        try await Firestore.firestore().enableNetwork()
        print("[NetworkModeManager] - Network enabled")
      } else {
        try await Firestore.firestore().disableNetwork()
        print("[NetworkModeManager] - Network disabled (offline mode)")
      }
    } catch {
      print("[NetworkModeManager] - Failed to change network state: \(error)")
    }
  }
}
