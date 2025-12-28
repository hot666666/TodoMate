//
//  SyncManager.swift
//  TodoMate
//
//  Created by agent on 12/28/25.
//

import FirebaseFirestore

@MainActor
@Observable
final class SyncManager {
  private let db: Firestore
  private let authManager: AuthManager

  private(set) var isSyncEnabled: Bool = false

  var canEnableSync: Bool {
    guard let user = authManager.currentUser else { return false }
    return user.authorized
  }

  init(db: Firestore, authManager: AuthManager) {
    self.db = db
    self.authManager = authManager
  }

  func enableSync() async throws {
    guard canEnableSync else {
      Log.warning(
        "Cannot enable sync: user not authorized. User must sign in with a social account to enable sync.",
        category: .sync
      )
      return
    }

    do {
      try await db.enableNetwork()
      isSyncEnabled = true
      Log.info("Network enabled", category: .sync)
    } catch {
      // Ensure sync flag reflects the actual network state on failure
      isSyncEnabled = false
      Log.warning("Failed to enable network: \(error)", category: .sync)
      throw error
    }
  }

  func disableSync() async throws {
    do {
      try await db.disableNetwork()
      isSyncEnabled = false
      Log.info("Network disabled", category: .sync)
    } catch {
      // If disabling fails, keep sync flagged as enabled
      isSyncEnabled = true
      Log.warning("Failed to disable network: \(error)", category: .sync)
      throw error
    }
  }

  /// 앱 시작 시 기본 오프라인 모드로 시작
  func initializeOfflineMode() async throws {
    do {
      try await db.disableNetwork()
      isSyncEnabled = false
      Log.info("Initialized in offline mode", category: .sync)
    } catch {
      // Initialization in offline mode failed; leave current sync state as-is
      Log.warning("Failed to initialize offline mode: \(error)", category: .sync)
      throw error
    }
  }
}
