//
//  PublicFeatureWrapper.swift
//  TodoMate
//
//  Created by agent on 1/10/26.
//

import SwiftUI

/// Firebase 및 Auth를 사용하는 Public 기능을 감싸는 래퍼 뷰.
/// 이 뷰의 생명주기에 따라 PublicDIContainer 및 관련 Store들이 생성되고 해제됩니다.
struct PublicFeatureWrapper<Content: View>: View {
  @State private var publicDI: PublicDIContainer
  @State private var sessionStore: SessionStore
  @State private var todoStore: TodoStore
  @State private var memoStore: MemoStore
  @State private var messageStore: MessageStore
  @State private var networkManager: NetworkModeManager

  private let content: () -> Content

  init(core: CoreDIContainer, @ViewBuilder content: @escaping () -> Content) {
    let container = PublicFeatureWrapper.composePublicContainer()
    _publicDI = State(initialValue: container)
    _sessionStore = State(initialValue: SessionStore(container: container))
    _todoStore = State(initialValue: TodoStore(container: container))
    _memoStore = State(initialValue: MemoStore(container: container))
    _messageStore = State(initialValue: MessageStore(container: container))
    _networkManager = State(
      initialValue: NetworkModeManager(container: container, core: core))
    self.content = content

    Log.info("PublicDIContainer initialized", category: .app)
  }

  var body: some View {
    content()
      .environment(publicDI)
      .environment(sessionStore)
      .environment(todoStore)
      .environment(memoStore)
      .environment(messageStore)
      .environment(networkManager)
      .task {
        // Start listening to auth changes
        todoStore.startListening(to: sessionStore.events())
        memoStore.startListening(to: sessionStore.events())
        messageStore.startListening(to: sessionStore.events())
        sessionStore.startListeningToAuthChanges()
      }
      .onDisappear {
        // Force cleanup when the view is removed from the hierarchy
        sessionStore.cleanup()
        todoStore.cleanup()
        memoStore.cleanup()
        messageStore.cleanup()
        Log.info("PublicDIContainer cleaned up", category: .app)
      }
  }

  // Legacy composition logic moved from TodoMateApp
  private static func composePublicContainer() -> PublicDIContainer {
    let userRepo = FirestoreUserRepository()
    let todoRepo = FirestoreTodoRepository()
    let messageRepo = FirestoreMessageRepository()
    let memoRepo = FirestoreMemoRepository()
    let groupRepo = FirestoreGroupRepository()
    let authService = FirebaseAuthService()
    let messageReadTracker = MessageReadTrackerImpl()
    let networkController = FirestoreNetworkController()

    return PublicDIContainer(
      userRepository: userRepo,
      todoRepository: todoRepo,
      messageRepository: messageRepo,
      memoRepository: memoRepo,
      groupRepository: groupRepo,
      authService: authService,
      messageReadTracker: messageReadTracker,
      networkController: networkController,
    )
  }
}
