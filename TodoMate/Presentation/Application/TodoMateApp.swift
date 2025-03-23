//
//  TodoMateApp.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import FirebaseCore
import SwiftData
import SwiftUI
import WidgetKit

@main
struct TodoMateApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @Environment(\.scenePhase) private var scenePhase

  private let windowDimensions: WindowDimensions
  private let sharedModelContainer: ModelContainer

  init() {
    FirebaseApp.configure()

    windowDimensions = WindowDimensions()

    sharedModelContainer = SharedModelContainer.create()
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

  // MARK: - Helper Methods

  private func postNotification(action: ShortcutActions) {
    print("[TodoMateApp] - NotificationCenter를 통한 \(action) 알림 전송")
    NotificationCenter.default.post(
      name: .shortcutAction,
      object: nil,
      userInfo: ["action": action.rawValue]
    )
  }

  private func handleScenePhaseChange(_ newPhase: ScenePhase) {
    guard newPhase != .active else { return }
    print("[TodoMateApp] - SwiftData 모델 컨테이너 저장 및 위젯 갱신")
    try? sharedModelContainer.mainContext.save()
    WidgetCenter.shared.reloadAllTimelines()
  }
}

private struct _TodoMateApp: View {
  @State private var container: DIContainer
  @State private var authManager: AuthManager

  init(modelContainer: ModelContainer) {
    #if PREVIEW
      let container: DIContainer = .stub
    #else
      // TODO: - 의존성 순서 리팩토링
      let widgetDataManager = WidgetDataManager(modelContainer: modelContainer)
      let userRepository = FirestoreUserRepository()
      let userService = UserService(userRepository: userRepository)
      let googleSignInService = GoogleSignInService()
      let authService = AuthService(
        userService: userService,
        googleSignInService: googleSignInService
      )
      let authenticatedUserCacheService = AuthenticatedUserCacheService()
      let todoService = TodoService()
      let todoOrderService = TodoOrderService()
      let userGroupCacheService = UserGroupCacheService()

      let container: DIContainer = .init(
        authService: authService,
        googleSignInService: googleSignInService,
        widgetDataManager: widgetDataManager,
        userService: userService,
        todoService: todoService,
        chatService: ChatService(),
        chatStreamProvider: FirestoreChatStreamProvider(),
        todoStreamProvider: FirestoreTodoStreamProvider(),
        todoOrderService: todoOrderService,
        authenticatedUserCacheService: AuthenticatedUserCacheService(),
        userGroupCacheService: userGroupCacheService,

        // MARK: - UseCase

        fetchAuthenticatedUserUseCase: LoadCachedAuthenticatedUserUseCase(
          userInfoService: authenticatedUserCacheService
        ),
        fetchTodosByUserUseCase: FetchUserGroupTodosWithOrderUseCase(
          todoService: todoService,
          todoOrderService: todoOrderService
        ),
        saveUserTodosOrderUseCase: SaveUserTodosOrderUseCase(
          todoOrderService: todoOrderService
        ),
        syncWidgetDataWithUserTodoUseCase: SyncWidgetDataWithUserTodoUseCase(
          widgetDataManager: widgetDataManager
        ),
        signInUseCase: SignInUseCase(
          authService: authService,
          authenticatedUserCacheService: authenticatedUserCacheService,
          userRepoitory: userRepository,
          userGroupCacheService: userGroupCacheService
        ),
        signOutUseCase: SignOutUseCase(
          authService: authService,
          authenticatedUserCacheService: authenticatedUserCacheService,
          userGroupCacheService: userGroupCacheService,
          widgetDataManager: widgetDataManager
        )
      )
    #endif
    _container = State(initialValue: container)
    _authManager = State(initialValue: AuthManager(
      fetchAuthenticatedUserUseCase: container.fetchAuthenticatedUserUseCase,
      signInUseCase: container.signInUseCase,
      signOutUseCase: container.signOutUseCase
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
      // TODO: - 상태마다 뷰모델을 중복 생성 중)
      MainView(viewModel: .init(container: container, authenticatedUser: signedInUser))
        .environment(container)
    case .loading:
      ProgressView()
    }
  }
}

#Preview {
  _TodoMateApp(modelContainer: .forPreview())
}
