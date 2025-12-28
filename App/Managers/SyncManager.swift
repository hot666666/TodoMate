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
    isSyncEnabled = true
    try await db.enableNetwork()
    Log.info("Network enabled", category: .sync)
  }

  func disableSync() async throws {
    isSyncEnabled = false
    try await db.disableNetwork()
    Log.info("Network disabled", category: .sync)
  }

  /// 앱 시작 시 기본 오프라인 모드로 시작
  func initializeOfflineMode() async throws {
    isSyncEnabled = false
    try await db.disableNetwork()
    Log.info("Initialized in offline mode", category: .sync)
  }
}
