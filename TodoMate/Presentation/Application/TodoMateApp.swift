//
//  TodoMateApp.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftData
import SwiftUI
import WidgetKit
import FirebaseCore

@main
struct TodoMateApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @Environment(\.scenePhase) private var scenePhase

  private let windowDimensions: WindowDimensions
  private let sharedModelContainer: ModelContainer

  init() {
		FirebaseApp.configure()

    windowDimensions = WindowDimensions()

    sharedModelContainer = Self.createModelContainer()
  }

  var body: some Scene {
    WindowGroup {
      _TodoMateApp(modelContainer: sharedModelContainer)
    }
    .modelContainer(sharedModelContainer)
    .commands {
      CommandGroup(replacing: .appInfo) {
        Button("업데이트") {
          appDelegate.checkForUpdates()
        }
      }
      CommandMenu("단축키") {
        Button("Todo 생성") {
          postNotification(action: .createUserTodo)
        }
        .keyboardShortcut("n")

        Button("오버레이 닫기") {
          postNotification(action: .closeOverlay)
        }
        .keyboardShortcut(.escape)
      }
    }
    .onChange(of: scenePhase) { _, newPhase in
      handleScenePhaseChange(newPhase)
    }
    .defaultSize(width: windowDimensions.width, height: windowDimensions.height)
    .defaultPosition(.center)
    .windowStyle(.hiddenTitleBar)
  }

  // MARK: - Static Helpers

  private static func createModelContainer() -> ModelContainer {
    let schema = Schema([WidgetTodo.self])

    #if DEBUG || PREVIEW
      let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    #else
      let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    #endif

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }

  // MARK: - Helper Methods

  private func postNotification(action: ShortcutAction) {
    print("Posting \(action)")
    NotificationCenter.default.post(
      name: .shortcutAction,
      object: nil,
      userInfo: ["action": action.rawValue]
    )
  }

  private func handleScenePhaseChange(_ newPhase: ScenePhase) {
    guard newPhase != .active else { return }
    print("Save ModelContainer and Reload widget timeline")
    try? sharedModelContainer.mainContext.save()
    WidgetCenter.shared.reloadAllTimelines()
  }
}

private struct _TodoMateApp: View {
  @State private var container: DIContainer
  @State private var authManager: AuthManager

  init(modelContainer: ModelContainer) {
    #if PREVIEW
      let container: DIContainer = .init(
        authService: StubAuthService(),
        googleSignInService: StubGoogleSignInService(),
        widgetDataManager: WidgetDataManager(modelContainer: modelContainer),
        userService: StubUserService(),
        todoService: TodoService(), /// 테스트용 reference 구현
        chatService: StubChatService(),
        groupService: StubGroupService(),
        chatStreamProvider: FirestoreChatStreamProvider(),
        todoStreamProvider: FirestoreTodoStreamProvider(), /// 테스트용 reference 구현
        userInfoService: UserInfoService(), /// 외부에서 저장위치(UserDefualt key) 설정
        todoOrderService: StubTodoOrderService()
      ) /// 외부에서 저장위치(UserDefualt key) 설정
    #else
      // TODO: - 의존성 순서 리팩토링
      let userService = UserService()
      let googleSignInService = GoogleSignInService()

      let container: DIContainer = .init(
        authService: AuthService(
          userService: userService,
          googleSignInService: googleSignInService
        ),
        googleSignInService: googleSignInService,
        widgetDataManager: WidgetDataManager(modelContainer: modelContainer),
        userService: userService,
        todoService: TodoService(),
        chatService: ChatService(),
        groupService: GroupService(),
        chatStreamProvider: FirestoreChatStreamProvider(),
        todoStreamProvider: FirestoreTodoStreamProvider(),
        userInfoService: UserInfoService(),
        todoOrderService: TodoOrderService()
      )
    #endif
    _container = State(initialValue: container)
    _authManager = State(initialValue: AuthManager(
      authenticationUseCase: container.authenticationUseCase,
      fetchAuthenticatedUserUseCase: container.fetchAuthenticatedUserUseCase
    ))
  }

  var body: some View {
    content
      .environment(authManager)
  }

  @ViewBuilder
  private var content: some View {
    switch authManager.state {
    case .signedOut:
      AuthView()
    case let .signedIn(signedInUser):
      MainView(userInfo: signedInUser)
        .environment(container)
    case .loading:
      ProgressView()
    }
  }
}

#Preview {
  _TodoMateApp(modelContainer: .forPreview())
}
