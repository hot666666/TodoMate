//
//  AppDependencies.swift
//  TodoMate
//
//  Created by agent on 12/28/25.
//

import FirebaseFirestore

@MainActor
@Observable
final class AppDependencies {
  let authManager: AuthManager
  let syncManager: SyncManager

  init() {
    let db = Firestore.firestore()
    let authManager = AuthManager()
    let syncManager = SyncManager(db: db, authManager: authManager)

    self.authManager = authManager
    self.syncManager = syncManager
  }
}
