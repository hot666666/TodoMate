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
  @FocusState private var focusedMessageId: String?
  @State private var selectedMessageId: String?
  @State private var editingText: String = ""
  @State private var originalText: String = ""
  @Binding var isEditingMessage: Bool

  private var hasChanges: Bool {
    editingText.trimmingCharacters(in: .whitespacesAndNewlines) != originalText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  enum Action {
    case focusMessage(GroupMessage)
    case cancelEdit
    case endEditing
    case saveMessage(GroupMessage)
    case removeMessage(GroupMessage)
    case handleFocusChange(String?)
  }

  private func perform(_ action: Action) {
    switch action {
    case let .focusMessage(message):
      guard message.owner == sessionStore.userId, !isEditingMessage else { return }
      startEditingState(for: message)

    case .endEditing:
      clearEditingState()

    case .cancelEdit:
      editingText = originalText
      perform(.endEditing)

    case let .saveMessage(message):
      guard let updatedMessage = message.withUpdatedContent(editingText) else { return }
      messageStore.update(updatedMessage, userId: sessionStore.userId)
      perform(.endEditing)

    case let .removeMessage(message):
      overlayManager.presentConfirmation(
        title: "메시지 삭제",
        message: "이 메시지를 삭제하시겠습니까?",
        destructiveActionTitle: "삭제"
      ) {
        messageStore.delete(message, userId: sessionStore.userId)
      }

    case let .handleFocusChange(newValue):
      guard newValue == nil else { return }
      if hasChanges {
        focusedMessageId = selectedMessageId
      } else {
        perform(.endEditing)
      }
    }
  }

  private func startEditingState(for message: GroupMessage) {
    selectedMessageId = message.id
    editingText = message.content
    originalText = message.content
    focusedMessageId = message.id
    isEditingMessage = true
  }

  private func clearEditingState() {
    selectedMessageId = nil
    editingText = ""
    originalText = ""
    focusedMessageId = nil
    isEditingMessage = false
  }
}

extension MessageListSection {
  var body: some View {
    ScrollViewReader { _ in
      List {
        scrollAnchor
        ForEach(messageStore.messages) { message in
          if selectedMessageId == message.id {
            editingMessageView(for: message)
          } else {
            displayMessageView(for: message)
          }
        }
      }
      .listModifiers()
      .onChange(of: focusedMessageId) { _, newValue in
        perform(.handleFocusChange(newValue))
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
      if !isEditingMessage {
        perform(.focusMessage(message))
      }
    }
    .opacity(isEditingMessage && message.owner == sessionStore.userId ? 0.5 : 1.0)
    .contextMenu {
      if message.owner == sessionStore.userId, !isEditingMessage {
        Button("삭제") {
          perform(.removeMessage(message))
        }
      }
    }
  }

  private func messageTextEditor(for message: GroupMessage) -> some View {
    TextEditor(text: $editingText)
      .focused($focusedMessageId, equals: message.id)
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
          perform(.saveMessage(message))
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
        .buttonStyle(GlassmorphismButtonStyle(isSecondary: true))

        Button("확인") {
          perform(.saveMessage(message))
        }
        .buttonStyle(GlassmorphismButtonStyle(isSecondary: false))
      }
    }
    .padding(.leading, 5)
  }

  private var scrollAnchor: some View {
    Color.clear
      .frame(height: 1)
      .id("top")
  }
}

private extension View {
  func listModifiers() -> some View {
    listStyle(.inset)
      .scrollContentBackground(.hidden)
      .background(.clear)
  }
}

#Preview {
  MessageListSection(isEditingMessage: .constant(false))
    .environment(SessionStore.preview)
    .environment(MessageStore.preview)
    .environment(OverlayManager())
}
