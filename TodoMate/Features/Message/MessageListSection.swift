//
//  MessageListSection.swift
//  Todo
//
//  Created by hs on 6/9/25.
//

import SwiftUI

struct MessageListSection: View {
  @Environment(SessionStore.self) private var sessionStore
  @Environment(MessageStore.self) private var messageStore
  @Environment(OverlayManager.self) private var overlayManager
  @State private var editingText: String = ""
  let messageScreenState: MessageScreenState

  enum Action {
    case selectMessage(GroupMessage)
    case cancelEdit
    case updateEdit
    case removeMessage(GroupMessage)
  }

  private func perform(_ action: Action) {
    switch action {
    case let .selectMessage(message):
      guard message.owner == sessionStore.userId, !messageScreenState.isEditingMessage else { return }
      editingText = message.content
      messageScreenState.selectMessage(message)

    case .cancelEdit:
      messageScreenState.selectMessage(nil)

    case .updateEdit:
      guard
        let message = messageScreenState.selectedMessage,
        let updatedMessage = message.withUpdatedContent(editingText)
      else { return }
      messageStore.update(updatedMessage, userId: sessionStore.userId)
      perform(.cancelEdit)

    case let .removeMessage(message):
      overlayManager.presentConfirmation(
        title: "메시지 삭제",
        message: "이 메시지를 삭제하시겠습니까?",
        destructiveActionTitle: "삭제"
      ) {
        messageStore.delete(message, userId: sessionStore.userId)
      }
    }
  }
}

extension MessageListSection {
  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 8) {
          ForEach(messageStore.messages) { message in
            if let mid = messageScreenState.selectedMessage?.id, mid == message.id {
              editingMessageView(for: message)
            } else {
              displayMessageView(for: message)
            }
          }
          .padding(.horizontal, MessageDesignSystem.Component.MessageInput.containerPadding)

          scrollAnchor
        }
      }
      .onAppear {
        DispatchQueue.main.async {
          proxy.scrollTo("bottom", anchor: .bottom)
        }
      }
      .onChange(of: messageStore.messages.count) { _, _ in
        withAnimation {
          proxy.scrollTo("bottom", anchor: .bottom)
        }
      }
    }
  }

  private func editingMessageView(for message: GroupMessage) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      messageTextEditor(for: message)
      editingControls(for: message)
    }
    .padding(MessageDesignSystem.Component.MessageList.itemPadding)
    .background(.ultraThinMaterial, in: .rect(cornerRadius: MessageDesignSystem.CornerRadius.medium))
    .padding(.bottom)
  }

  private func displayMessageView(for message: GroupMessage) -> some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(message.content)
      Text("\(sessionStore.userGroupDisplayNames[message.owner] ?? "???") at \(message.createdAt.formattedForMessage)")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding(.bottom)
    .contentShape(.rect)
    .onTapGesture {
      if !messageScreenState.isEditingMessage {
        perform(.selectMessage(message))
      }
    }
    .opacity(messageScreenState.isEditingMessage ? 0.5 : 1.0)
    .contextMenu {
      if message.owner == sessionStore.userId, !messageScreenState.isEditingMessage {
        Button("삭제") {
          perform(.removeMessage(message))
        }
      }
    }
  }

  private func messageTextEditor(for _: GroupMessage) -> some View {
    TextEditor(text: $editingText)
      .font(MessageDesignSystem.Component.Typography.contentFont)
      .textFieldStyle(.plain)
      .background(Color.clear)
      .scrollContentBackground(.hidden)
      .frame(
        minHeight: MessageDesignSystem.Component.MessageList.editingMinHeight,
        maxHeight: MessageDesignSystem.Component.MessageList.editingMaxHeight
      )
      .onKeyPress(.return, phases: .down) { key in
        if key.modifiers.contains(.command) {
          perform(.updateEdit)
          return .handled
        }
        return .ignored
      }
  }

  private func editingControls(for message: GroupMessage) -> some View {
    HStack {
      Text("최근 수정 at \(message.updatedAt.formattedForMessage)")
        .font(.caption)
        .foregroundColor(.secondary)

      Spacer()

      HStack(spacing: 8) {
        Button("취소") {
          perform(.cancelEdit)
        }
        .buttonStyle(GlassmorphismButtonStyle(disabled: true))

        Button("확인") {
          perform(.updateEdit)
        }
        .buttonStyle(GlassmorphismButtonStyle(disabled: false))
      }
    }
    .padding(.leading, 5)
  }

  private var scrollAnchor: some View {
    Color.clear
      .frame(height: 30)
      .id("bottom")
  }
}

#Preview {
  MessageListSection(messageScreenState: .init())
    .environment(SessionStore.preview)
    .environment(MessageStore.preview)
    .environment(OverlayManager())
}
