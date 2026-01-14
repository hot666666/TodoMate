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
  public static func configure() {
    configureFirebaseAndAuth()

    // FirestoreReference 초기화가 필요한 경우 여기서 수행하거나
    // FirestoreReference.shared 같은 싱글톤이 lazy라면 접근만으로 초기화될 수 있음
    // 기존 앱 코드에서 FirestoreReference.shared 초기화 로직이 보이지 않았으나,
    // 필요하다면 여기서 명시적으로 수행
    _ = FirestoreReference.shared
  }

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
