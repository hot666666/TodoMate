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

  // MARK: - Dependency Injection Container

  private let appContainer: AppDIContainer
  private let modelContainer: ModelContainer

  // Public Stores & DI
  @State private var publicDI: PublicDIContainer
  @State private var networkModeManager: NetworkModeManager
  @State private var sessionStore: SessionStore
  @State private var todoStore: TodoStore
  @State private var messageStore: MessageStore

  init() {
    // 1. Create SwiftData Container
    let schema = Schema([SDTodo.self, SDMemo.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: false)

    do {
      modelContainer = try ModelContainer(for: schema, configurations: [config])
    } catch {
      fatalError("Failed to create ModelContainer: \(error)")
    }

    // 2. Core & App DI
    let core = CoreDIContainer(
      userDefaults: .standard,
      modelContext: modelContainer.mainContext,
    )
    appContainer = AppDIContainer(core: core)

    // 3. Public DI Composition
    // (Logic moved from PublicFeatureWrapper)
    let composition = TodoMateApp.composePublicContainer(core: core)
    _publicDI = State(initialValue: composition.container)
    _networkModeManager = State(initialValue: composition.networkModeManager)
    _sessionStore = State(initialValue: SessionStore(container: composition.container))
    _todoStore = State(initialValue: TodoStore(container: composition.container))
    _messageStore = State(initialValue: MessageStore(container: composition.container))

    // 4. Configure Firebase
    TodoMateApp.configureFirebase()
  }

  var body: some Scene {
    WindowGroup {
      MainView()
        .environment(appContainer)
        .environment(appContainer.core)
        // Private Stores
        .environment(PrivateTodoStore(container: appContainer.core))
        .environment(PrivateMemoStore(container: appContainer.core))
        // Public Stores & DI
        .environment(publicDI)
        .environment(networkModeManager)
        .environment(sessionStore)
        .environment(todoStore)
        .environment(messageStore)
        // SwiftData Setup
        .modelContainer(modelContainer)
        // Task
        .task {
          todoStore.startListening(to: sessionStore.events())
          messageStore.startListening(to: sessionStore.events())
          sessionStore.startListeningToAuthChanges()
        }
        .environment(\.colorScheme, .dark)
        .background(.ultraThickMaterial)
        .frame(minWidth: 720, minHeight: 540)
    }
    #if os(macOS)
    .windowStyle(.hiddenTitleBar)
    #endif
  }
}

// MARK: - Composition & Configuration Helper

extension TodoMateApp {
  private static func composePublicContainer(core: CoreDIContainer) -> (
    container: PublicDIContainer, networkModeManager: NetworkModeManager,
  ) {
    let firestoreReference = FirestoreReference()
    let networkController = FirestoreNetworkController(reference: firestoreReference)
    let networkModeManager = NetworkModeManager(
      userDefaults: core.userDefaults,
      networkController: networkController,
    )

    let userRepo = FirestoreUserRepository(reference: firestoreReference)
    let todoRepo = FirestoreTodoRepository(reference: firestoreReference)
    let messageRepo = FirestoreMessageRepository(reference: firestoreReference)
    let groupRepo = FirestoreGroupRepository(reference: firestoreReference)
    let authService = FirebaseAuthService()
    let messageReadTracker = MessageReadTrackerImpl()

    let container = PublicDIContainer(
      userRepository: userRepo,
      todoRepository: todoRepo,
      messageRepository: messageRepo,
      groupRepository: groupRepo,
      authService: authService,
      messageReadTracker: messageReadTracker,
    )

    return (container, networkModeManager)
  }

  static func configureFirebase() {
    // Check if Firebase is already configured
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    // Configure GIDSignIn
    if let clientId = FirebaseApp.app()?.options.clientID {
      GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    } else {
      Log.warning("Firebase client ID is not configured.")
    }
  }
}
