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

  init() {
    // Firebase 초기화 (Firestore 사용 전에 반드시 필요)
    if let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
       let options = FirebaseOptions(contentsOfFile: plistPath)
    {
      FirebaseApp.configure(options: options)
    } else {
      // 번들에 plist가 없는 경우 (Preview 등)
      print("[AppDependencies] GoogleService-Info.plist not found, Firebase not configured")
    }

    let db = Firestore.firestore()
    let authManager = AuthManager()
    let syncManager = SyncManager(db: db, authManager: authManager)

    self.authManager = authManager
    self.syncManager = syncManager
  }
}
