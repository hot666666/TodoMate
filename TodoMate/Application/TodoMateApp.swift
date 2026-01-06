//
//  TodoMateApp.swift
//  TodoMate
//
//  Created by hs on 6/2/25.
//

import FirebaseCore
import GoogleSignIn
import SwiftUI

@main
struct TodoMateApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  // MARK: - Stores (App Lifetime)

  @State private var sessionStore: SessionStore
  @State private var todoStore: TodoStore
  @State private var memoStore: MemoStore
  @State private var messageStore: MessageStore
  @State private var networkManager = NetworkModeManager()

  private let container: DIContainer

  init() {
    // 의존성 주입 컨테이너 생성
    let container = TodoMateApp.makeContainer()
    self.container = container

    // 앱 업데이트 체크 및 처리
    TodoMateApp.checkAndHandleAppUpdate(container: container)

    // Store 생성
    let session = SessionStore(container: container)
    let todo = TodoStore(container: container)
    let memo = MemoStore(container: container)
    let message = MessageStore(container: container)

    // State 초기화
    _sessionStore = State(initialValue: session)
    _todoStore = State(initialValue: todo)
    _memoStore = State(initialValue: memo)
    _messageStore = State(initialValue: message)

    // AppDelegate에 cleanup 핸들러 등록 (앱 종료 시 gRPC timeout 방지)
    appDelegate.cleanupHandler = { [session, todo, memo, message] in
      session.cleanup()
      todo.cleanup()
      memo.cleanup()
      message.cleanup()
    }
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(container)
        .environment(sessionStore)
        .environment(todoStore)
        .environment(memoStore)
        .environment(messageStore)
        .environment(networkManager)
        .environment(\.colorScheme, .dark)
        .background(Color.customDarkBg)
        .background(.ultraThickMaterial)
        .frame(minWidth: 720)
    }
    #if os(macOS)
    .windowStyle(.hiddenTitleBar)
    #endif
  }
}

private extension TodoMateApp {
  static func makeContainer() -> DIContainer {
    if isPreview {
      return .preview
    }

    configureFirebase()
    configureGoogleSignIn()

    let userRepo = FirestoreUserRepository()
    let todoRepo = FirestoreTodoRepository()
    let messageRepo = FirestoreMessageRepository()
    let memoRepo = FirestoreMemoRepository()
    let authService = FirebaseAuthService()
    let calendarDayService = CalendarDayServiceImpl()
    let messageReadTracker = MessageReadTrackerImpl()

    return DIContainer(
      userRepository: userRepo,
      todoRepository: todoRepo,
      messageRepository: messageRepo,
      memoRepository: memoRepo,
      authService: authService,
      calendarDayService: calendarDayService,
      messageReadTracker: messageReadTracker,
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

  static func checkAndHandleAppUpdate(container: DIContainer) {
    let userDefaults = UserDefaults.standard

    let currentVersion =
      Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    let lastVersion = userDefaults.string(forKey: "app_last_version")

    print(
      "[TodoMateApp] - Current version: \(currentVersion), Last version: \(lastVersion ?? "none")")

    // 업데이트 기록이 존재하면 작업 x -> 3.0.0 이전버전에서 업데이트 시, 수행
    if lastVersion == nil {
      print("[TodoMateApp] - First launch detected. Initializing app state...")
      try? container.authService.signOut()

      // 앱의 모든 UserDefaults 데이터 삭제
      if let bundleIdentifier = Bundle.main.bundleIdentifier {
        userDefaults.removePersistentDomain(forName: bundleIdentifier)
      }
    }

    // 현재 버전 저장
    userDefaults.set(currentVersion, forKey: "app_last_version")
  }
}
