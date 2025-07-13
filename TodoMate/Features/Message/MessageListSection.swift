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
  @State private var isEditing: Bool = false

  @Binding var isEditingMessage: Bool

  private func updateSelectedMessage(with focusState: String?) {
    selectedMessageId = focusState
  }

  private func focus(_ message: GroupMessage) {
    guard message.owner == sessionStore.userId else { return }
    guard !isEditing else { return } // 다른 메시지 수정 중일 때 선택 방지

    selectedMessageId = message.id
    editingText = message.content
    originalText = message.content
    isEditing = true
    focusedMessageId = message.id

    isEditingMessage = true
  }

  private func cancelEdit() {
    editingText = originalText
    endEditing()
  }

  private func endEditing() {
    selectedMessageId = nil
    editingText = ""
    originalText = ""
    isEditing = false
    focusedMessageId = nil

    isEditingMessage = false
  }

  private func hasChanges() -> Bool {
    editingText.trimmingCharacters(in: .whitespacesAndNewlines) != originalText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func saveMessage(_ message: GroupMessage) {
    let trimmed = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }

    var updated = message
    updated.content = trimmed
    updated.updatedAt = Date()
    messageStore.update(updated, userId: sessionStore.userId)

    endEditing()
  }

  private func removeMessage(_ message: GroupMessage) {
    overlayManager.presentConfirmation(
      title: "메시지 삭제",
      message: "이 메시지를 삭제하시겠습니까?",
      destructiveActionTitle: "삭제"
    ) {
      messageStore.delete(message, userId: sessionStore.userId)
    }
  }
}

extension MessageListSection {
  var body: some View {
    ScrollViewReader { proxy in
      List {
        // 스크롤 앵커 포인트
        Color.clear
          .frame(height: 1)
          .id("top")

        ForEach(messageStore.messages) { message in
          if selectedMessageId == message.id {
            VStack(alignment: .leading, spacing: 8) {
              TextEditor(text: $editingText)
                .focused($focusedMessageId, equals: message.id)
                .font(MessageDesignSystem.Component.Typography.contentFont)
                .textFieldStyle(.plain)
                .background(Color.clear)
                .scrollContentBackground(.hidden)
                .frame(minHeight: MessageDesignSystem.Component.MessageList.editingMinHeight, maxHeight: MessageDesignSystem.Component.MessageList.editingMaxHeight)
                // Command + Enter to save message
                .onKeyPress(.return, phases: .down) { key in
                  if key.modifiers.contains(.command) {
                    saveMessage(message)
                    return .handled
                  }
                  return .ignored
                }
                // Escape to cancel
                .onKeyPress(.escape, phases: .down) { _ in
                  cancelEdit()
                  return .handled
                }

              HStack {
                Text("최근 수정 at \(message.updatedAt.formattedForMessage)")
                  .font(.caption)
                  .foregroundColor(.secondary)

                Spacer()

                // 취소/확인 버튼
                HStack(spacing: 8) {
                  Button("취소") {
                    cancelEdit()
                  }
                  .buttonStyle(GlassmorphismButtonStyle(isSecondary: true))

                  Button("확인") {
                    saveMessage(message)
                  }
                  .buttonStyle(GlassmorphismButtonStyle(isSecondary: false))
                }
              }
              .padding(.leading, 5)
            }
            .padding(MessageDesignSystem.Component.MessageList.itemPadding)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: MessageDesignSystem.CornerRadius.medium))
            .padding(.bottom)
          } else {
            VStack(alignment: .leading, spacing: 5) {
              Text(message.content)
              Text("\(sessionStore.userGroupDisplayNames[message.owner] ?? "???") at \(message.createdAt.formattedForMessage)")
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.bottom)
            .contentShape(.rect)
            .onTapGesture {
              if !isEditing { // 수정 중이 아닐 때만 선택 가능
                focus(message)
              }
            }
            .opacity(isEditing && message.owner == sessionStore.userId ? 0.5 : 1.0) // 수정 중일 때 시각적 피드백
            .contextMenu {
              if message.owner == sessionStore.userId, !isEditing {
                Button("삭제") {
                  removeMessage(message)
                }
              }
            }
          }
        }
      }
      .onChange(of: focusedMessageId) { _, newValue in
        if newValue == nil, isEditing {
          // 변경사항이 있으면 포커스를 다시 설정하여 편집 모드 유지
          if hasChanges() {
            focusedMessageId = selectedMessageId
          } else {
            // 변경사항이 없으면 편집 종료
            endEditing()
          }
        }
      }
      .onChange(of: messageStore.messages.count) { _, _ in
        withAnimation(.easeInOut(duration: 0.3)) {
          proxy.scrollTo("top", anchor: .top)
        }
      }
      .listStyle(.inset)
      .scrollContentBackground(.hidden)
      .background(.clear)
    }
  }
}

#Preview {
  MessageListSection(isEditingMessage: .constant(false))
    .environment(SessionStore.preview)
    .environment(MessageStore.preview)
    .environment(OverlayManager())
}
