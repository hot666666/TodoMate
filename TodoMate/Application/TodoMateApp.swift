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

  @State private var networkManager: NetworkModeManager
  @State private var sessionStore: SessionStore
  @State private var todoStore: TodoStore
  @State private var memoStore: MemoStore
  @State private var messageStore: MessageStore

  private let container: DIContainer

  init() {
    // 의존성 주입 컨테이너 생성
    let container = TodoMateApp.makeContainer()
    self.container = container

    // 앱 업데이트 체크 및 처리
    TodoMateApp.checkAndHandleAppUpdate(container: container)

    // NetworkModeManager 초기화
    _networkManager = State(initialValue: .init())

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
    guard !isPreview else { return .preview }

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
}
