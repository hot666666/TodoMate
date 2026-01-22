//
//  TodoMateApp.swift
//  TodoMate
//
//  Created by hs on 6/2/25.
//

import AppIntents
import Common
import SwiftData
import SwiftUI
import TodoMateData
import TodoMateDomain

@main
struct TodoMateApp: App {
  // MARK: - Dependencies

  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  private let appDIContainer: AppDIContainer
  private let overlayViewController: OverlayViewController

  // MARK: - State

  @State private var todoBoardStore: TodoBoardStore
  @State private var memoStore: MemoStore

  init() {
    // Firebase 및 GoogleSignIn 설정 후, DI Container 생성
    let container: AppDIContainer
    #if DEBUG
      DebugConfiguration.configureFirebase()
      container = DebugConfiguration.makeContainer() ?? Self.composeContainer()
    #else
      TodoMateDataConfiguration.configure()
      container = Self.composeContainer()
    #endif
    appDIContainer = container

    // 앱 업데이트 체크 및 처리
    Self.checkAndHandleAppUpdate(container: container)

    // 스토어 초기화
    let todoBoardStore = TodoBoardStore(container: container.core)
    _todoBoardStore = State(initialValue: todoBoardStore)
    _memoStore = State(initialValue: MemoStore(container: container.core))

    // OverlayVC 생성 및 WindowManager 등록
    overlayViewController = Self.composeVCandRegisterHotKey(container: container, store: todoBoardStore)
    WindowManager.shared.overlayController = overlayViewController

    // AppIntent에서 사용할 수 있도록 CoreDIContainer 등록
    AppDependencyManager.shared.add(dependency: container.core)
  }

  var body: some Scene {
    // MARK: - Menu Bar

    MenuBarExtra("TodoMate", systemImage: "checklist") {
      MenuBarView()
        .environment(todoBoardStore)
        .modelContainer(appDIContainer.core.modelContainer)
    }
    .menuBarExtraStyle(.menu)

    // MARK: - Window

    Window("TodoMate", id: AppSceneID.mainApp.rawValue) {
      MainView(container: appDIContainer)
        .defaultAppStorage(appDIContainer.core.userDefaults)
        .modelContainer(appDIContainer.core.modelContainer)
        .environment(appDIContainer.core)
        .environment(todoBoardStore)
        .environment(memoStore)
        .environment(appDIContainer)
        .environment(\.colorScheme, .dark)
        .background(.ultraThickMaterial)
        .frame(minWidth: 1000, minHeight: 625)
        .task {
          #if DEBUG
            MockDataSeeder.seedIfNeeded(container: appDIContainer.core.modelContainer)
          #endif
        }
    }
    #if os(macOS)
    .windowStyle(.hiddenTitleBar)
    .commands {
      // File 메뉴: 새 윈도우 (⇧⌘N)
      CommandGroup(replacing: .newItem) {
        Button("새 윈도우") {
          WindowManager.shared.openMainWindow()
        }
        .keyboardShortcut("n", modifiers: [.command, .shift])
      }

      // 앱 메뉴: 업데이트 확인 (⌥⌘U)
      CommandGroup(after: .appInfo) {
        Button("업데이트 확인") {
          appDelegate.checkForUpdates()
        }
        .keyboardShortcut("u", modifiers: [.command, .option])
      }
    }
    #endif
  }
}

// MARK: - Container Composition

private extension TodoMateApp {
  static func composeVCandRegisterHotKey(container: AppDIContainer, store: TodoBoardStore) -> OverlayViewController {
    let overlayVC = OverlayViewController(coreDI: container.core, todoBoardStore: store)

    // 시스템 레벨 글로벌 단축키: 오버레이 토글 (⇧⌘Space)
    container.core.hotKeyManager.register(
      key: .space,
      modifiers: [.command, .shift],
      handler: {
        WindowManager.shared.toggleOverlay()
      },
    )

    return overlayVC
  }

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
    let config = ModelConfiguration(
      AppEnvironment.Container.name,
      schema: schema,
      isStoredInMemoryOnly: false,
    )

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
  // TODO: - 정리
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
