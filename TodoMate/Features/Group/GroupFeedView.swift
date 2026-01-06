//
//  GroupFeedView.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import PhotosUI
import SwiftUI

struct GroupFeedView: View {
  @Environment(SessionStore.self) private var sessionStore
  @Environment(TodoStore.self) private var todoStore
  @Environment(MessageStore.self) private var messageStore

  @State private var viewModel = GroupFeedViewModel()
  @State private var isChatVisible = true
  @State private var chatPanelWidth: CGFloat = 340

  private let minChatWidth: CGFloat = 280
  private let maxChatWidth: CGFloat = 500

  var body: some View {
    Group {
      if sessionStore.userGroupId.isEmpty {
        GroupFeedNoGroupView()
      } else {
        contentView
      }
    }
  }

  private var contentView: some View {
    HStack(spacing: 0) {
      // Main Content
      VStack(spacing: 0) {
        headerView
        feedContent
      }
      .frame(maxWidth: .infinity)

      // Resizable Chat Panel (trailing)
      if isChatVisible {
        resizableChatPanel
      }
    }
    .background(Color(nsColor: .windowBackgroundColor))
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        if !isChatVisible {
          Button {
            withAnimation(.easeInOut(duration: 0.2)) {
              isChatVisible = true
            }
          } label: {
            Image(systemName: "bubble.left.and.bubble.right.fill")
              .foregroundStyle(.blue)
          }
        }
      }
    }
  }

  private var resizableChatPanel: some View {
    HStack(spacing: 0) {
      // Resize Handle
      Rectangle()
        .fill(Color.clear)
        .frame(width: 6)
        .contentShape(Rectangle())
        .onHover { hovering in
          if hovering {
            NSCursor.resizeLeftRight.push()
          } else {
            NSCursor.pop()
          }
        }
        .gesture(
          DragGesture()
            .onChanged { value in
              let newWidth = chatPanelWidth - value.translation.width
              chatPanelWidth = min(maxChatWidth, max(minChatWidth, newWidth))
            },
        )

      ChatPanelView(
        viewModel: viewModel,
        sessionStore: sessionStore,
        messageStore: messageStore,
        onClose: {
          withAnimation(.easeInOut(duration: 0.2)) {
            isChatVisible = false
          }
        },
      )
      .frame(width: chatPanelWidth)
      .transition(.move(edge: .trailing))
    }
  }

  // MARK: - Header

  private var headerView: some View {
    HStack {
      HStack(spacing: 12) {
        Image(systemName: "briefcase.fill")
          .foregroundStyle(.secondary)

        // Using userGroupId or a placeholder name since Group name isn't directly in SessionStore
        // Ideally we fetch Group entity, but for now we show "My Group" or lookup name from userGroupDisplayNames?
        // Logic: specific group name retrieval might need update in SessionStore.
        Text("Design Team") // Placeholder/Mock for now as per instructions to migrate existing UI.
          .font(.title3)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)

        Text("Group")
          .font(.caption2)
          .fontWeight(.medium)
          .foregroundStyle(.blue)
          .padding(.horizontal, 8)
          .padding(.vertical, 2)
          .background(Color.blue.opacity(0.1))
          .clipShape(Capsule())
      }

      Spacer()

      HStack(spacing: 16) {
        // User Avatars
        HStack(spacing: -10) {
          ForEach(sessionStore.userGroup.prefix(3)) { member in
            // Avatar placeholder since User entity doesn't have avatarUrl yet
            Circle()
              .fill(Color.blue.opacity(0.3))
              .frame(width: 32, height: 32)
              .overlay(
                Text(member.displayName.prefix(1).uppercased())
                  .font(.caption)
                  .fontWeight(.bold)
                  .foregroundStyle(.blue),
              )
              .overlay(Circle().stroke(.white, lineWidth: 2))
          }

          if sessionStore.userGroup.count > 3 {
            Text("+\(sessionStore.userGroup.count - 3)")
              .font(.caption2)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)
              .frame(width: 32, height: 32)
              .background(Color.gray.opacity(0.1))
              .clipShape(Circle())
          }
        }

        Button {
          // More actions
        } label: {
          Image(systemName: "ellipsis")
            .font(.system(size: 20))
            .foregroundStyle(.secondary)
            .padding(8)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 16)
  }

  // MARK: - Feed Content

  private var feedContent: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 24) {
        ForEach(sessionStore.userGroup) { member in
          GroupMemberSection(
            user: member,
            todos: (todoStore.todos[member.id] ?? []).map { ViewTodo(from: $0) },
          )
        }
      }
      .padding(24)
    }
  }
}

// MARK: - Group Member Section

private struct GroupMemberSection: View {
  let user: User
  let todos: [ViewTodo]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header
      HStack(spacing: 12) {
        Circle()
          .fill(Color.blue.opacity(0.3))
          .frame(width: 40, height: 40)
          .overlay(
            Text(user.displayName.prefix(1).uppercased())
              .font(.headline)
              .fontWeight(.bold)
              .foregroundStyle(.blue),
          )

        VStack(alignment: .leading, spacing: 2) {
          Text(user.displayName)
            .font(.subheadline)
            .fontWeight(.semibold)

          Text("Member")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      // Todos
      if todos.isEmpty {
        HStack(spacing: 12) {
          Image(systemName: "circle.dashed")
            .font(.system(size: 20))
            .foregroundStyle(.tertiary)
          Text("No tasks shared")
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
      } else {
        VStack(alignment: .leading, spacing: 8) {
          ForEach(todos) { todo in
            SharedTodoRow(todo: todo)
          }
        }
      }
    }
    .padding(.bottom, 16)
  }
}

// MARK: - Chat Panel View

private struct ChatPanelView: View {
  @Bindable var viewModel: GroupFeedViewModel
  var sessionStore: SessionStore
  var messageStore: MessageStore
  var onClose: () -> Void

  // Removed Photo Picker state for now as it's not supported by domain

  var body: some View {
    VStack(spacing: 0) {
      // Messages
      ScrollViewReader { proxy in
        ScrollView {
          LazyVStack(spacing: 16) {
            Text("TODAY")
              .font(.caption2)
              .fontWeight(.bold)
              .foregroundStyle(.secondary)
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(Color.secondary.opacity(0.1))
              .clipShape(Capsule())
              .padding(.top, 10)

            ForEach(messageStore.messages) { message in
              // Convert GroupMessage to ChatMessage for display
              let chatMsg = ViewGroupMessage(from: message, senderId: message.owner)
              let sender = viewModel.getMember(byId: message.owner, sessionStore: sessionStore)
              let viewUser = sender.map { ViewUser(from: $0) }

              ChatMessageBubble(
                message: chatMsg,
                isMe: message.owner == sessionStore.userId,
                user: viewUser,
              )
              .id(message.id)
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

      // Input
      chatInput
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        chatHeader
      }
    }
    .background(.ultraThinMaterial)
  }

  private var chatHeader: some View {
    Button(action: onClose) {
      Image(systemName: "arrow.right.to.line")
    }
  }

  private var chatInput: some View {
    VStack(spacing: 0) {
      // Removed image preview section

      HStack(spacing: 8) {
        // Removed Photo Picker button

        TextField("Write a message...", text: $viewModel.chatInputText)
          .textFieldStyle(.plain)
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(Color(nsColor: .textBackgroundColor))
          .clipShape(RoundedRectangle(cornerRadius: 8))

        // Send button
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
    }
    .background(Color(nsColor: .separatorColor).opacity(0.05))
  }
}

#Preview {
  GroupFeedView()
    .environment(SessionStore.preview)
    .environment(TodoStore.preview)
    .environment(MessageStore.preview)
}
