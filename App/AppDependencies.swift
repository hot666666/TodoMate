//
//  AppDependencies.swift
//  TodoMate
//
//  Created by agent on 12/28/25.
//

import FirebaseCore
import FirebaseFirestore

@MainActor
@Observable
final class AppDependencies {
  let authManager: AuthManager
  let syncManager: SyncManager
  let groupManager: GroupManager
  let todoManager: TodoManager

  init() {
    // Firebase 초기화 (Firestore 사용 전에 반드시 필요)

    let db = Firestore.firestore()
    let authManager = AuthManager(db: db)
    let syncManager = SyncManager(db: db, authManager: authManager)
    let inviteCodeGenerator = InviteCodeGenerator()
    let groupManager = GroupManager(
      db: db, authManager: authManager, inviteCodeGenerator: inviteCodeGenerator,
    )
    let todoManager = TodoManager(db: db, authManager: authManager)

    self.authManager = authManager
    self.syncManager = syncManager
    self.groupManager = groupManager
    self.todoManager = todoManager
  }
}
