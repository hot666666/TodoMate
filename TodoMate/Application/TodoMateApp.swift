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
  @State private var container: DIContainer
  private let modelContainer: ModelContainer

  init() {
    modelContainer = TodoMateApp.makeModelContainer()
    container = TodoMateApp.makeContainer(with: modelContainer)

    // 앱 업데이트 체크 및 처리
    TodoMateApp.checkAndHandleAppUpdate(modelContainer: modelContainer, container: container)
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(\.colorScheme, .dark)
        .environment(container)
        .background(Color.customDarkBg)
        .background(.ultraThickMaterial)
    }
    .modelContainer(modelContainer)
    #if os(macOS)
      .windowToolbarStyle(.unifiedCompact)
      .windowStyle(.hiddenTitleBar)
    #endif
  }
}

private extension TodoMateApp {
  static func makeModelContainer() -> ModelContainer {
    let schema = Schema([WidgetTodo.self])

    #if DEBUG
      let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    #else
      let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    #endif

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("[TodoMateApp] - Could not create ModelContainer: \(error)")
    }
  }

  static func makeContainer(with modelContainer: ModelContainer) -> DIContainer {
    if isPreview {
      return .preview
    }

    configureFirebase()
    configureGoogleSignIn()

    let userRepo = FirestoreUserRepository()
    let todoRepo = FirestoreTodoRepository()
    let todoOrderRepo = UserDefaultsTodoOrderRepository()
    let messageRepo = FirestoreMessageRepository()
    let memoRepo = FirestoreMemoRepository()
    let authService = FirebaseAuthService()
    let calendarDayService = CalendarDayServiceImpl()
    let widgetSyncService = SwiftDataWidgetSyncService(
      todoRepository: todoRepo,
      authService: authService,
      modelContext: modelContainer.mainContext
    )
    let messageReadTracker = MessageReadTrackerImpl()

    return DIContainer(
      userRepository: userRepo,
      todoRepository: todoRepo,
      todoOrderRepository: todoOrderRepo,
      messageRepository: messageRepo,
      memoRepository: memoRepo,
      authService: authService,
      calendarDayService: calendarDayService,
      widgetSyncService: widgetSyncService,
      messageReadTracker: messageReadTracker
    )
  }

  static var isPreview: Bool {
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
  }

  static func configureFirebase() {
    FirebaseApp.configure()
  }

  static func configureGoogleSignIn() {
    guard let clientId = FirebaseApp.app()?.options.clientID else {
      print("[TodoMateApp] - Firebase client ID is not configured.")
      return
    }
    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
  }

  static func checkAndHandleAppUpdate(modelContainer: ModelContainer, container: DIContainer) {
    let userDefaults = UserDefaults.standard

    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    let lastVersion = userDefaults.string(forKey: "app_last_version")

    print("[TodoMateApp] - Current version: \(currentVersion), Last version: \(lastVersion ?? "none")")

    // 업데이트 기록이 존재하면 작업 x -> 3.0.0 이전버전에서 업데이트 시, 수행
    if lastVersion == nil {
      print("[TodoMateApp] - First launch detected. Initializing app state...")
      try? container.authService.signOut()

      // 앱의 모든 UserDefaults 데이터 삭제
      if let bundleIdentifier = Bundle.main.bundleIdentifier {
        userDefaults.removePersistentDomain(forName: bundleIdentifier)
      }

      // 앱의 모든 SwiftData 데이터 삭제
      let context = modelContainer.mainContext
      try? context.delete(model: WidgetTodo.self)
      try? context.save()
    }

    // 현재 버전 저장
    userDefaults.set(currentVersion, forKey: "app_last_version")
  }
}
