//
//  TodoMateApp.swift
//  TodoMate
//
//  Created by hs on 6/2/25.
//

import AppIntents
import Common
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
    let container: AppDIContainer
    #if DEBUG
      container = DebugConfiguration.makeContainer() ?? Self.composeContainer()
    #else
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
    }
    .menuBarExtraStyle(.menu)

    // MARK: - Window

    Window("TodoMate", id: AppSceneID.mainApp.rawValue) {
      MainView(container: appDIContainer)
        .defaultAppStorage(appDIContainer.core.userDefaults)
        .environment(appDIContainer.core)
        .environment(todoBoardStore)
        .environment(memoStore)
        .environment(appDIContainer)
        .environment(\.colorScheme, .dark)
        .background(.ultraThickMaterial)
        .frame(minWidth: 1000, minHeight: 625)
        .task {
          #if DEBUG
            await MockDataSeeder.seedIfNeeded(container: appDIContainer.core)
          #endif
        }
    }
    #if os(macOS)
    .windowStyle(.hiddenTitleBar)
    .defaultLaunchBehavior(.presented)
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
    let database: GRDBDatabase
    do {
      database = try GRDBDatabase(storage: projectDatabaseStorage())
    } catch {
      Log.error("Failed to create GRDB database: \(error)")
      fatalError("Failed to create GRDB database: \(error)")
    }

    return CoreDIContainer(
      database: database,
      userDefaults: userDefaults,
      hotKeyManager: hotKeyManager,
      projectIDGenerator: projectIDGenerator(),
    )
  }

  nonisolated static func projectDatabaseStorage(
    arguments: [String] = ProcessInfo.processInfo.arguments,
  ) -> GRDBDatabase.Storage {
    guard
      let flagIndex = arguments.firstIndex(of: "--ui-testing-project-database-id"),
      arguments.indices.contains(flagIndex + 1)
    else {
      return .shared
    }

    let databaseID = arguments[flagIndex + 1]
      .filter { $0.isLetter || $0.isNumber || $0 == "-" }
    precondition(!databaseID.isEmpty, "UI testing Project database ID must not be empty")
    let databaseURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("TodoMateProjectJourney-\(databaseID).sqlite")

    if arguments.contains("--ui-testing-reset-project-database") {
      for suffix in ["", "-shm", "-wal"] {
        try? FileManager.default.removeItem(atPath: databaseURL.path + suffix)
      }
    }
    return .file(databaseURL)
  }

  nonisolated static func projectIDGenerator(
    arguments: [String] = ProcessInfo.processInfo.arguments,
  ) -> @Sendable () -> ProjectID {
    guard
      let flagIndex = arguments.firstIndex(of: "--ui-testing-project-id"),
      arguments.indices.contains(flagIndex + 1)
    else {
      return { ProjectID(rawValue: UUID().uuidString) }
    }
    let projectID = ProjectID(rawValue: arguments[flagIndex + 1])
    return { projectID }
  }

  static func createPublicDIContainer(userDefaults: UserDefaults) -> PublicDIContainer {
    let messageReadTracker = MessageReadTrackerImpl(userDefaults: userDefaults)

    return PublicDIContainer(
      userRepository: StubUserRepository(),
      todoRepository: StubTodoRepository(),
      messageRepository: StubMessageRepository(),
      groupRepository: StubGroupRepository(),
      connectivityRepository: StubConnectivityRepository(),
      legacyImportRepository: StubLegacyImportRepository(),
      authService: StubAuthService(),
      messageReadTracker: messageReadTracker,
    )
  }
}

// MARK: - App Update Handling

private extension TodoMateApp {
  /// Legacy app-update cleanup remains outside the Project workspace slice.
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
