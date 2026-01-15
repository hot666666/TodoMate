//
//  TodoMateDataConfiguration.swift
//  TodoMateData
//
//  Created by agent on 1/14/26.
//

import Common
import FirebaseCore
import GoogleSignIn

public enum TodoMateDataConfiguration {
  /// TodoMateData 및 관련 설정(Firebase 등) 초기화
  @MainActor
  public static func configure(mode: FirestoreReference.Mode = .production) {
    configureFirebaseAndAuth()

    // FirestoreReference 초기화
    FirestoreReference.configure(mode: mode)
  }

  @MainActor
  private static func configureFirebaseAndAuth() {
    FirebaseApp.configure()
    Log.info("Firebase configured successfully.", category: .data)

    if let clientId = FirebaseApp.app()?.options.clientID {
      GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
      Log.info("Google Sign-In configured with client ID: \(clientId)", category: .auth)
    } else {
      Log.warning("Firebase client ID is not configured.", category: .data)
    }
  }
}
