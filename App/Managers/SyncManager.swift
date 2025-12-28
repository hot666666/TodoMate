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
      print("[SyncManager] Cannot enable sync: user not authorized")
      return
    }
    try await db.enableNetwork()
    isSyncEnabled = true
    print("[SyncManager] Network enabled")
  }

  func disableSync() async throws {
    try await db.disableNetwork()
    isSyncEnabled = false
    print("[SyncManager] Network disabled")
  }

  /// 앱 시작 시 기본 오프라인 모드로 시작
  func initializeOfflineMode() async throws {
    try await db.disableNetwork()
    isSyncEnabled = false
    print("[SyncManager] Initialized in offline mode")
  }
}
