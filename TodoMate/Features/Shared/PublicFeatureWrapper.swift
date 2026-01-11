//
//  PublicFeatureWrapper.swift
//  TodoMate
//
//  Created by agent on 1/10/26.
//

import FirebaseCore
import GoogleSignIn
import SwiftUI

/// Firebase 및 Auth를 사용하는 Public 기능을 감싸는 래퍼 뷰.
/// 이 뷰의 생명주기에 따라 PublicDIContainer 및 관련 Store들이 생성되고 해제됩니다.
struct PublicFeatureWrapper<Content: View>: View {
  @State private var publicDI: PublicDIContainer
  @State private var networkModeManager: NetworkModeManager
  @State private var sessionStore: SessionStore
  @State private var todoStore: TodoStore
  @State private var messageStore: MessageStore

  private let content: () -> Content

  init(core: CoreDIContainer, @ViewBuilder content: @escaping () -> Content) {
    let composition = PublicFeatureWrapper.composePublicContainer(core: core)
    _publicDI = State(initialValue: composition.container)
    _networkModeManager = State(initialValue: composition.networkModeManager)
    _sessionStore = State(initialValue: SessionStore(container: composition.container))
    _todoStore = State(initialValue: TodoStore(container: composition.container))
    _messageStore = State(initialValue: MessageStore(container: composition.container))
    self.content = content

    Log.info("PublicDIContainer initialized", category: .app)

    // Configure Firebase lazily when Public context is requested
    PublicFeatureWrapper.configureFirebase()
    PublicFeatureWrapper.configureGoogleSignIn()
  }

  var body: some View {
    content()
      .environment(publicDI)
      .environment(networkModeManager)
      .environment(sessionStore)
      .environment(todoStore)
      .environment(messageStore)
      .task {
        // Start listening to auth changes
        todoStore.startListening(to: sessionStore.events())
        messageStore.startListening(to: sessionStore.events())
        sessionStore.startListeningToAuthChanges()
      }
      .onDisappear {
        // Force cleanup when the view is removed from the hierarchy
        sessionStore.cleanup()
        todoStore.cleanup()
        messageStore.cleanup()
        Log.info("PublicDIContainer cleaned up", category: .app)
      }
  }

  // Legacy composition logic moved from TodoMateApp
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
}

private extension PublicFeatureWrapper {
  static func configureFirebase() {
    // FirebaseApp.configure() should be called only once
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
  }

  static func configureGoogleSignIn() {
    guard let clientId = FirebaseApp.app()?.options.clientID else {
      Log.warning("Firebase client ID is not configured.")
      return
    }
    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
  }
}
