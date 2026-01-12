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
  /// Private Todo/MemoStore 생성
  @State private var todoStore: PrivateTodoStore
  @State private var memoStore: PrivateMemoStore

  init() {
    /// Firebaes, Google Sign-In 초기화
    Self.configureFirebaseAndAuth()
    /// DI 컨테이너 생성
    let coreDI = Self.createCoreDIContainer()
    let publicDI = Self.createPublicDIContainer()
    appDIContainer = AppDIContainer(coreContainer: coreDI, publicContainer: publicDI)
    /// Store 객체 초기화
    _todoStore = State(initialValue: PrivateTodoStore(container: coreDI))
    _memoStore = State(initialValue: PrivateMemoStore(container: coreDI))
  }

  var body: some Scene {
    WindowGroup {
      MainView(container: appDIContainer)
        .environment(appDIContainer)
        .environment(todoStore)
        .environment(memoStore)
        .modelContainer(appDIContainer.core.modelContainer)
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
  static func createCoreDIContainer() -> CoreDIContainer {
    let userDefaults = UserDefaults.standard
    let container = Self.createSwiftDataModelContainer()

    return CoreDIContainer(
      modelContainer: container,
      userDefaults: userDefaults,
    )
  }

  static func createPublicDIContainer() -> PublicDIContainer {
    let firestoreReference = FirestoreReference()
    let authService = FirebaseAuthService()
    let userRepo = FirestoreUserRepository(reference: firestoreReference)
    let todoRepo = FirestoreTodoRepository(reference: firestoreReference)
    let messageRepo = FirestoreMessageRepository(reference: firestoreReference)
    let groupRepo = FirestoreGroupRepository(reference: firestoreReference)

    let connectivityRepo = FirestoreConnectivityRepository(reference: firestoreReference)
    let messageReadTracker = MessageReadTrackerImpl()

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

  static func configureFirebaseAndAuth() {
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
      Log.info("Firebase configured successfully.")
    } else {
      Log.info("Firebase is already configured.")
    }

    if let clientId = FirebaseApp.app()?.options.clientID {
      GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
      Log.info("Google Sign-In configured with client ID: \(clientId)")
    } else {
      Log.warning("Firebase client ID is not configured.")
    }
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
