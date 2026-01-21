//
//  GroupFeedWrapperView.swift
//  TodoMate
//
//  Created by agent on 1/12/26.
//

import SwiftUI

struct GroupFeedWrapperView: View {
  @Environment(SessionStore.self) private var sessionStore
  /// TodoStore, MemoStore 생성 및 바인딩
  @State private var todoStore: TodoStore
  @State private var messageStore: MessageStore

  init(container: AppDIContainer) {
    _todoStore = State(initialValue: TodoStore(container: container.pub))
    _messageStore = State(initialValue: MessageStore(container: container.pub))
  }

  private func bind() {
    /// AuthState -> TodoStore, MemoStore
    todoStore.startListening(to: sessionStore.streamEvents)
    messageStore.startListening(to: sessionStore.streamEvents)
  }

  private func cleanup() {
    todoStore.cleanup()
    messageStore.cleanup()
  }

  var body: some View {
    Group {
      if sessionStore.hasGroup {
        GroupFeedView()
      } else {
        GroupFeedNoGroupView()
      }
    }
    .environment(todoStore)
    .environment(messageStore)
    .task {
      bind()
    }
    .onDisappear {
      cleanup()
    }
  }
}
