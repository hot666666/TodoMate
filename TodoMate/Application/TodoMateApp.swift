//
//  TodoMateApp.swift
//  TodoMate
//
//  Created by hs on 6/2/25.
//

import FirebaseCore
import GoogleSignIn
import SwiftData
import SwiftUI

@main
struct TodoMateApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  // MARK: - Dependency Injection Container

  private let appContainer: AppDIContainer
  private let modelContainer: ModelContainer

  init() {
    // Firebase 및 Google Sign-In 구성 (App 레벨에서 미리 수행)
    TodoMateApp.configureFirebase()
    TodoMateApp.configureGoogleSignIn()

    // Create SwiftData Container
    let schema = Schema([SDTodo.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: false)

    do {
      modelContainer = try ModelContainer(for: schema, configurations: [config])
    } catch {
      fatalError("Failed to create ModelContainer: \(error)")
    }

    // 최상위 DI 컨테이너 생성 (Core 포함)
    // 최상위 DI 컨테이너 생성 (Core 포함)
    let networkController = FirestoreNetworkController()
    let core = CoreDIContainer(
      userDefaults: .standard,
      modelContext: modelContainer.mainContext,
      networkController: networkController,
    )
    appContainer = AppDIContainer(core: core)

    // 앱 업데이트 체크 및 처리 (기존 로직 유지 가능하지만 container 타입 변경 필요)
    // TodoMateApp.checkAndHandleAppUpdate(container: container)
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(appContainer)
        .environment(appContainer)
        .environment(appContainer.core)
        .environment(appContainer.networkModeManager)
        .environment(PrivateTodoStore(container: appContainer.core))
        .modelContainer(modelContainer)
        .environment(\.colorScheme, .dark)
        .background(.ultraThickMaterial)
        .frame(minWidth: 720, minHeight: 540)
    }
    #if os(macOS)
    .windowStyle(.hiddenTitleBar)
    #endif
  }
}

private extension TodoMateApp {
  static func configureFirebase() {
    // FirebaseApp.configure()는 앱 수명 주기 당 한 번만 호출되어야 함
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
  }

  static func configureGoogleSignIn() {
    guard let clientId = FirebaseApp.app()?.options.clientID else {
      Log.warning("Firebase client ID is not configured.")
      return
    }
    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
  }
}
