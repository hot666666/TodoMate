//
//  MessageInputSection.swift
//  Todo
//
//  Created by hs on 6/9/25.
//

import SwiftUI

struct MessageInputSection: View {
  @Environment(SessionStore.self) private var sessionStore
  @Environment(MessageStore.self) private var messageStore
  @State private var inputText: String = ""

  enum Action {
    case sendMessage
  }

  private func perform(_ action: Action) {
    switch action {
    case .sendMessage:
      let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { return }
      let message = GroupMessage(
        content: trimmed,
        groupId: sessionStore.userGroupId,
        owner: sessionStore.userId
      )
      messageStore.add(message, userId: sessionStore.userId)
      inputText = ""
    }
  }
}

extension MessageInputSection {
  var body: some View {
    VStack {
      TextEditor(text: $inputText)
        .offset(x: -5, y: 3)
        .overlay(alignment: .topLeading) {
          if inputText.isEmpty {
            Text("메시지를 입력하세요")
              .foregroundColor(.secondary)
              .allowsHitTesting(false)
          }
        }
        .scrollContentBackground(.hidden)
        .frame(minHeight: MessageDesignSystem.Component.MessageInput.minHeight, maxHeight: MessageDesignSystem.Component.MessageInput.maxHeight, alignment: .bottom)
        .fixedSize(horizontal: false, vertical: true)
        .padding()
        .onKeyPress(.return, phases: .down) { key in
          if key.modifiers.contains(.command) {
            perform(.sendMessage)
            return .handled
          }
          return .ignored
        }

      messageInputButtons
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
        .frame(height: MessageDesignSystem.Component.MessageInput.containerHeight)
    }
    .background(Color.customLightDark, in: .rect(cornerRadius: MessageDesignSystem.CornerRadius.large))
  }

  private var messageInputButtons: some View {
    HStack {
      // TODO: - 이미지/파일 업로드
      Button(action: {}) {
        Image(systemName: "plus")
          .font(.system(size: MessageDesignSystem.Component.MessageInput.plusButtonSize, weight: .bold))
      }
      .buttonStyle(.plain)
      .disabled(true)

      Spacer()
      Button(action: {
        perform(.sendMessage)
      }) {
        Image(systemName: "arrow.up.circle.fill")
          .font(.system(size: MessageDesignSystem.Component.MessageInput.buttonSize, weight: .bold))
      }
      .buttonStyle(.plain)
      .disabled(inputText.isEmpty)
    }
  }
}

#Preview {
  VStack {
    Spacer()
      .frame(minHeight: 100)
    MessageInputSection()
      .environment(SessionStore.preview)
      .environment(MessageStore.preview)
  }
  .background(Color.red)
  .frame(height: 600)
}
