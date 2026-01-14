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
  private let appDIContainer: AppDIContainer

  // MARK: - Global States(App Lifetime)

  @State private var todoStore: PrivateTodoStore
  @State private var memoStore: PrivateMemoStore

  init() {
    /// Firebase 및 인증 설정
    Self.configureFirebaseAndAuth()
    /// DI Container 생성
    let container = Self.makeContainer()
    appDIContainer = container
    /// 앱 업데이트 체크 및 처리
    Self.checkAndHandleAppUpdate(container: container)
    /// Store 초기화
    _todoStore = State(initialValue: PrivateTodoStore(container: container.core))
    _memoStore = State(initialValue: PrivateMemoStore(container: container.core))
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
            if Self.isUITesting {
              MockDataSeeder.seed(container: appDIContainer.core.modelContainer)
            }
          #endif
          await todoStore.loadTodos()
          await memoStore.load()
        }
    }
    #if os(macOS)
    .windowStyle(.hiddenTitleBar)
    #endif
  }

  #if DEBUG
    static var isUITesting: Bool {
      ProcessInfo.processInfo.arguments.contains("-useMockContainer")
    }
  #endif
}

private extension TodoMateApp {
  @MainActor
  static func makeContainer() -> AppDIContainer {
    #if DEBUG
      if isUITesting {
        let scenario = parseSenarioFromArguments()
        return AppDIContainer.makeMock(for: scenario)
      }
    #endif

    return composeContainer()
  }

  @MainActor
  static func composeContainer() -> AppDIContainer {
    let userDefaults = UserDefaults.standard
    let hotKeyManager = HotKeyManager()
    let coreDI = createCoreDIContainer(userDefaults: userDefaults, hotKeyManager: hotKeyManager)
    let publicDI = createPublicDIContainer(userDefaults: userDefaults)

    return AppDIContainer(coreContainer: coreDI, publicContainer: publicDI)
  }
}

private extension TodoMateApp {
  static func configureFirebaseAndAuth() {
    FirebaseApp.configure()
    Log.info("Firebase configured successfully.")

    if let clientId = FirebaseApp.app()?.options.clientID {
      GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
      Log.info("Google Sign-In configured with client ID: \(clientId)")
    } else {
      Log.warning("Firebase client ID is not configured.")
    }
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
