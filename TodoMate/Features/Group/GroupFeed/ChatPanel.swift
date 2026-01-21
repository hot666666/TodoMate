//
//  ChatPanel.swift
//  TodoMate
//
//  Created by agent on 1/21/26.
//

import SwiftUI
import TodoMateDomain

struct ChatPanel: View {
  // MARK: - Environment

  @Environment(SessionStore.self) private var sessionStore
  @Environment(TodoStore.self) private var todoStore
  @Environment(MessageStore.self) private var messageStore

  // MARK: - Properties

  @Bindable var viewModel: GroupFeedViewModel

  // MARK: - Computed Properties

  private var groupedMessages: [(date: Date, messages: [GroupMessage])] {
    Dictionary(grouping: messageStore.messages) { message in
      Calendar.current.startOfDay(for: message.createdAt)
    }
    .map { (date: $0.key, messages: $0.value.sorted { $0.createdAt < $1.createdAt }) }
    .sorted { $0.date < $1.date }
  }

  // MARK: - Body

  var body: some View {
    VStack(spacing: 0) {
      messagesView
      chatInput
    }
    .background(.ultraThinMaterial)
  }
}

// MARK: - Subviews

private extension ChatPanel {
  var messagesView: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(spacing: 16) {
          ForEach(groupedMessages, id: \.date) { group in
            dateHeader(for: group.date)

            ForEach(group.messages) { message in
              messageRow(for: message)
                .id(message.id)
            }
          }
        }
        .padding(16)
      }
      .onChange(of: messageStore.messages.count) {
        if let lastId = messageStore.messages.last?.id {
          withAnimation {
            proxy.scrollTo(lastId, anchor: .bottom)
          }
        }
      }
    }
  }

  func dateHeader(for date: Date) -> some View {
    Text(DateHeaderFormatter.format(date))
      .font(.caption2)
      .fontWeight(.bold)
      .foregroundStyle(.secondary)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(Color.secondary.opacity(0.1))
      .clipShape(Capsule())
      .padding(.top, 10)
  }

  func messageRow(for message: GroupMessage) -> some View {
    let chatMsg = ViewGroupMessage(from: message, senderId: message.owner)
    let sender = viewModel.getMember(byId: message.owner, sessionStore: sessionStore)
    let isMe = message.owner == sessionStore.userId

    return HStack(alignment: .bottom, spacing: 2) {
      if isMe {
        Spacer()
        Text(message.createdAt.formatted(date: .omitted, time: .shortened))
          .font(.caption2)
          .foregroundStyle(.tertiary)
        ChatMessageBubble(message: chatMsg, isMe: true, user: sender)
      } else {
        ChatMessageBubble(message: chatMsg, isMe: false, user: sender)
        Text(message.createdAt.formatted(date: .omitted, time: .shortened))
          .font(.caption2)
          .foregroundStyle(.tertiary)
        Spacer()
      }
    }
  }

  var chatInput: some View {
    HStack(spacing: 8) {
      TextField("Write a message...", text: $viewModel.chatInputText)
        .textFieldStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))

      Button {
        viewModel.sendMessage(
          text: viewModel.chatInputText,
          image: nil,
          sessionStore: sessionStore,
          messageStore: messageStore,
        )
      } label: {
        Image(systemName: "paperplane.fill")
          .font(.system(size: 14))
          .foregroundStyle(.white)
          .frame(width: 32, height: 32)
          .background(Color.blue)
          .clipShape(Circle())
      }
      .buttonStyle(.plain)
      .disabled(viewModel.chatInputText.isEmpty)
    }
    .padding(12)
    .background(Color(nsColor: .separatorColor).opacity(0.05))
  }
}
