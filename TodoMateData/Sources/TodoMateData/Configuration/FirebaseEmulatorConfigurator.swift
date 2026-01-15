//
//  FirebaseEmulatorConfigurator.swift
//  TodoMateData
//
//  Created by agent on 1/14/26.
//

import FirebaseCore
import FirebaseFirestore
import GoogleSignIn

/// TodoMateData 테스트에서 GoogleService-Info.plist 없이 Firebase 에뮬레이터를 사용하기 위한 설정 유틸리티
public enum FirebaseEmulatorConfigurator {
  /// Firebase를 에뮬레이터 모드로 초기화
  /// - 더미 FirebaseOptions로 앱 설정
  /// - Firestore 에뮬레이터(localhost:8080) 연결
  /// - GoogleSignIn은 Firebase clientID가 없으므로 스킵
  public static func configure() {
    guard FirebaseApp.app() == nil else {
      // 이미 설정됨
      return
    }

    // GoogleService-Info.plist 없이 더미 옵션으로 초기화
    let options = FirebaseOptions(
      googleAppID: "1:000000000000:ios:0000000000000000000000",
      gcmSenderID: "000000000000",
    )
    options.projectID = "todomatedev"
    options.apiKey = "fake-api-key-for-emulator" // Auth 초기화에 필요

    FirebaseApp.configure(options: options)

    // Firestore 에뮬레이터 연결
    let settings = Firestore.firestore().settings
    settings.host = "127.0.0.1:8080"
    settings.isSSLEnabled = false
    settings.cacheSettings = MemoryCacheSettings()
    Firestore.firestore().settings = settings
  }

  /// GoogleSignIn 설정 (Firebase 초기화 후 호출, 옵셔널)
  /// - 에뮬레이터 모드에서는 clientID가 없으므로 스킵됨
  public static func configureGoogleSignInIfAvailable() {
    guard let clientId = FirebaseApp.app()?.options.clientID else {
      // 에뮬레이터 모드에서는 clientID가 없음 - 정상
      return
    }
    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
  }
}
