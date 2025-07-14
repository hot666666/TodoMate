//
//  MessageScreen.swift
//  Todo
//
//  Created by hs on 6/2/25.
//

import SwiftUI

struct MessageScreen: View {
  @Environment(SessionStore.self) private var sessionStore
  @Environment(MessageStore.self) private var messageStore

  @State private var isEditingMessage: Bool = false

  var body: some View {
    VStack(spacing: 0) {
      MessageListSection(isEditingMessage: $isEditingMessage)
      MessageInputSection()
        .padding(MessageDesignSystem.Component.MessageInput.containerPadding)
        .disabled(isEditingMessage)
        .opacity(isEditingMessage ? 0.5 : 1.0)
    }
    .task(id: sessionStore.userGroupId) {
      // MARK: - MessageScreen은 MainView의 Inspector여서, MainView가 로드되면 로드

      await messageStore.refresh(groupId: sessionStore.userGroupId)
    }
  }
}

#Preview {
  MessageScreen()
    .environment(SessionStore.preview)
    .environment(MessageStore.preview)
}
