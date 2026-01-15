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

  // MARK: - ViewController

  @State private var overlayViewController: OverlayViewController?

  // MARK: - Global States

  @State private var todoStore: PrivateTodoStore
  @State private var memoStore: PrivateMemoStore

  init() {
    // Firebase 및 인증 설정 후, DI Container 생성
    #if DEBUG
      DebugConfiguration.configureFirebase()
      appDIContainer = DebugConfiguration.makeContainer() ?? Self.composeContainer()
    #else
      TodoMateDataConfiguration.configure()
      appDIContainer = Self.composeContainer()
    #endif

    // AppIntent에서 사용할 수 있도록 공유 인스턴스 설정
    CoreDIContainer.shared = appDIContainer.core

    // 앱 업데이트 체크 및 처리
    Self.checkAndHandleAppUpdate(container: appDIContainer)

    // Store 초기화
    _todoStore = State(initialValue: PrivateTodoStore(container: appDIContainer.core))
    _memoStore = State(initialValue: PrivateMemoStore(container: appDIContainer.core))
  }

  var body: some Scene {
    WindowGroup {
      MainView(container: appDIContainer)
        .defaultAppStorage(appDIContainer.core.userDefaults)
        .modelContainer(appDIContainer.core.modelContainer)
        .environment(appDIContainer)
        .environment(todoStore)
        .environment(memoStore)
        .environment(\.colorScheme, .dark)
        .background(.ultraThickMaterial)
        .frame(minWidth: 720, minHeight: 540)
        .task {
          #if DEBUG
            MockDataSeeder.seedIfNeeded(container: appDIContainer.core.modelContainer)
          #endif
          if overlayViewController == nil {
            overlayViewController = OverlayViewController(
              diContainer: appDIContainer,
              modelContainer: appDIContainer.core.modelContainer,
              todoStore: todoStore,
            )
          }
          await todoStore.loadTodos()
          await memoStore.load()
        }
    }
    #if os(macOS)
    .windowStyle(.hiddenTitleBar)
    #endif

    // MARK: - Menu Bar

    MenuBarExtra("TodoMate", systemImage: "checklist") {
      MenuBarView { todo in
        overlayViewController?.show(with: todo)
      }
      .environment(todoStore)
    }
    .menuBarExtraStyle(.menu)
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
