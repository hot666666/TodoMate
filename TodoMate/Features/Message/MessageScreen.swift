//
//  MessageScreen.swift
//  Todo
//
//  Created by hs on 6/2/25.
//

import SwiftUI

@Observable
final class MessageScreenState {
  private(set) var selectedMessage: GroupMessage?
  var isEditingMessage: Bool { selectedMessage != nil }

  func selectMessage(_ message: GroupMessage?) {
    selectedMessage = message
  }
}

struct MessageScreen: View {
  @Environment(SessionStore.self) private var sessionStore
  @Environment(MessageStore.self) private var messageStore

  @State private var state: MessageScreenState = .init()

  var body: some View {
    VStack(spacing: 0) {
      MessageListSection(messageScreenState: state)
      MessageInputSection()
        .padding(MessageDesignSystem.Component.MessageInput.containerPadding)
        .disabled(state.isEditingMessage)
        .opacity(state.isEditingMessage ? 0.5 : 1.0)
    }
  }
}

#Preview {
  MessageScreen()
    .environment(SessionStore.preview)
    .environment(MessageStore.preview)
}
