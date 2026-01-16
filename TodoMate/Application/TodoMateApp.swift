//
//  TodoMateApp.swift
//  TodoMate
//
//  Created by hs on 6/2/25.
//

import Common
import SwiftData
import SwiftUI
import TodoMateData
import TodoMateDomain

@main
struct TodoMateApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  private let appDIContainer: AppDIContainer
  private let coreDIContainer: CoreDIContainer
  private let overlayViewController: OverlayViewController

  // MARK: - SwiftData(Todo, Memo) Helper

  @State private var todoStore: LocalTodoHelper
  @State private var memoStore: LocalMemoHelper

  init() {
    // Firebase 및 GoogleSignIn 설정 후, DI Container 생성
    #if DEBUG
      DebugConfiguration.configureFirebase()
      appDIContainer = DebugConfiguration.makeContainer() ?? Self.composeContainer()
    #else
      TodoMateDataConfiguration.configure()
      appDIContainer = Self.composeContainer()
    #endif

    // AppIntent에서 사용할 수 있도록 공유 인스턴스 설정
    CoreDIContainer.shared = appDIContainer.core
    coreDIContainer = appDIContainer.core

    // 앱 업데이트 체크 및 처리
    Self.checkAndHandleAppUpdate(container: appDIContainer)

    // Helper 초기화
    let todoHelper = LocalTodoHelper(container: appDIContainer.core)
    _todoStore = State(initialValue: todoHelper)
    _memoStore = State(initialValue: LocalMemoHelper(container: appDIContainer.core))

    // OverlayViewController 초기화
    overlayViewController = OverlayViewController(
      coreContainer: coreDIContainer,
      todoStore: todoHelper,
    )

    // 글로벌 단축키 등록 (⇧⌘Space)
    appDIContainer.core.hotKeyManager.register(
      key: .space,
      modifiers: [.command, .shift],
      handler: { [weak overlayViewController] in
        overlayViewController?.show()
      },
    )
  }

  var body: some Scene {
    // MARK: - Menu Bar

    MenuBarExtra("TodoMate", systemImage: "checklist") {
      MenuBarView { [weak overlayViewController] todo in
        overlayViewController?.show(with: todo)
      }
      .environment(todoStore)
      .modelContainer(coreDIContainer.modelContainer)
    }
    .menuBarExtraStyle(.menu)

    // MARK: - Window

    Window("TodoMate", id: AppSceneID.mainApp.rawValue) {
      MainView(container: appDIContainer)
        .defaultAppStorage(appDIContainer.core.userDefaults)
        .modelContainer(appDIContainer.core.modelContainer)
        .environment(appDIContainer)
        .environment(appDIContainer.core)
        .environment(todoStore)
        .environment(memoStore)
        .environment(\.colorScheme, .dark)
        .background(.ultraThickMaterial)
        .frame(minWidth: 720, minHeight: 540)
        .task {
          #if DEBUG
            MockDataSeeder.seedIfNeeded(container: appDIContainer.core.modelContainer)
          #endif
        }
    }
    #if os(macOS)
    .windowStyle(.hiddenTitleBar)
    #endif
  }
}

// MARK: - Container Composition

private extension TodoMateApp {
  @MainActor
  static func composeContainer() -> AppDIContainer {
    let userDefaults = UserDefaults.standard
    let hotKeyManager = HotKeyManager()
    let coreDI = createCoreDIContainer(userDefaults: userDefaults, hotKeyManager: hotKeyManager)
    let publicDI = createPublicDIContainer(userDefaults: userDefaults)

    return AppDIContainer(coreContainer: coreDI, publicContainer: publicDI)
  }

  static func createCoreDIContainer(
    userDefaults: UserDefaults,
    hotKeyManager: HotKeyManager,
  ) -> CoreDIContainer {
    let container = Self.createSwiftDataModelContainer()

    return CoreDIContainer(
      modelContainer: container,
      userDefaults: userDefaults,
      hotKeyManager: hotKeyManager,
    )
  }

  static func createPublicDIContainer(userDefaults: UserDefaults) -> PublicDIContainer {
    let firestoreReference = FirestoreReference.shared
    let authService = FirebaseAuthService()
    let userRepo = FirestoreUserRepository(reference: firestoreReference)
    let todoRepo = FirestoreTodoRepository(reference: firestoreReference)
    let messageRepo = FirestoreMessageRepository(reference: firestoreReference)
    let groupRepo = FirestoreGroupRepository(reference: firestoreReference)

    let connectivityRepo = FirestoreConnectivityRepository(reference: firestoreReference)
    let messageReadTracker = MessageReadTrackerImpl(userDefaults: userDefaults)

    return PublicDIContainer(
      userRepository: userRepo,
      todoRepository: todoRepo,
      messageRepository: messageRepo,
      groupRepository: groupRepo,
      connectivityRepository: connectivityRepo,
      authService: authService,
      messageReadTracker: messageReadTracker,
    )
  }

  static func createSwiftDataModelContainer() -> ModelContainer {
    let schema = Schema([SDTodo.self, SDMemo.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: false)

    do {
      let container = try ModelContainer(for: schema, configurations: [config])
      Log.info("SwiftData ModelContainer created successfully.")
      return container
    } catch {
      Log.error("Failed to create SwiftData ModelContainer: \(error)")
      fatalError("Failed to create ModelContainer: \(error)")
    }
  }
}

// MARK: - App Update Handling

private extension TodoMateApp {
  static func checkAndHandleAppUpdate(container: AppDIContainer) {
    let userDefaults = container.core.userDefaults

    let currentVersion =
      Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    let lastVersion = userDefaults.string(for: .appLastVersion)

    Log.info("Current version: \(currentVersion), Last version: \(lastVersion ?? "none")")

    #if DEBUG
      guard DebugConfiguration.isUsingMock else { return }
    #endif

    // 업데이트 기록이 존재하면 작업 x -> 3.0.0 이전버전에서 업데이트 시, 수행
    if lastVersion == nil {
      Log.info("First launch detected. Initializing app state...")
      try? container.pub.authService.signOut()

      if let bundleIdentifier = Bundle.main.bundleIdentifier {
        userDefaults.removePersistentDomain(forName: bundleIdentifier)
      }
    }

    // 현재 버전 저장
    userDefaults.set(currentVersion, for: .appLastVersion)
  }
}
