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

  // MARK: - Dependency Injection Container

  private let container: DIContainer

  // MARK: - Global States (App Lifetime)

  @State private var networkManager: NetworkModeManager
  @State private var sessionStore: SessionStore
  @State private var todoStore: TodoStore
  @State private var memoStore: MemoStore
  @State private var messageStore: MessageStore

  init() {
    // 의존성 주입 컨테이너 생성
    let container = TodoMateApp.makeContainer()
    self.container = container

    // 앱 업데이트 체크 및 처리
    TodoMateApp.checkAndHandleAppUpdate(container: container)

    // 앱 전역 상태 초기화
    _networkManager = State(initialValue: .init(container: container))

    let session = SessionStore(container: container)
    let todo = TodoStore(container: container)
    let memo = MemoStore(container: container)
    let message = MessageStore(container: container)

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
        .background(.ultraThickMaterial)
        .frame(minWidth: 720, minHeight: 540)
    }
    #if os(macOS)
    .windowStyle(.hiddenTitleBar)
    #endif
  }
}

private extension TodoMateApp {
  static func makeContainer() -> DIContainer {
    #if DEBUG
      if isUITesting {
        let scenario = parseSenarioFromArguments()
        return .makeMock(for: scenario)
      }
    #endif

    if isPreview {
      return .preview
    }

    return composeContainer()
  }

  static func composeContainer() -> DIContainer {
    // Firebase 및 Google Sign-In 구성
    // 만약 Preview에서 FirebaseSDK 관련요소를 쓰는부분이 있다면, 초기화를 안해서 크래시 발생(현재는 전부 격리라 문제없음)
    // 만약 Preview에서 그냥 config를 수행해버리면, db저장소를 점유하여 런타임에러 발생
    TodoMateApp.configureFirebase()
    TodoMateApp.configureGoogleSignIn()

    // 실제 구현체로 리포지토리 및 서비스 초기화
    let userRepo = FirestoreUserRepository()
    let todoRepo = FirestoreTodoRepository()
    let messageRepo = FirestoreMessageRepository()
    let memoRepo = FirestoreMemoRepository()
    let authService = FirebaseAuthService()
    let calendarDayService = CalendarDayServiceImpl()
    let messageReadTracker = MessageReadTrackerImpl()
    let networkController = FirestoreNetworkController()
    let userDefaults = UserDefaults.standard

    return DIContainer(
      userRepository: userRepo,
      todoRepository: todoRepo,
      messageRepository: messageRepo,
      memoRepository: memoRepo,
      authService: authService,
      calendarDayService: calendarDayService,
      messageReadTracker: messageReadTracker,
      networkController: networkController,
      userDefaults: userDefaults,
    )
  }

  static var isPreview: Bool {
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
  }

  #if DEBUG
    static var isUITesting: Bool {
      CommandLine.arguments.contains("--ui-testing")
    }
  #endif

  static func configureFirebase() {
    FirebaseApp.configure()
  }

  static func configureGoogleSignIn() {
    guard let clientId = FirebaseApp.app()?.options.clientID else {
      Log.warning("Firebase client ID is not configured.")
      return
    }
    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
  }
}
