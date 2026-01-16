//
//  GroupFeedView.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import Common
import SwiftUI
import TodoMateDomain

struct GroupFeedView: View {
  @Environment(SessionStore.self) private var sessionStore
  @Environment(TodoStore.self) private var todoStore
  @Environment(MessageStore.self) private var messageStore
  @Environment(AppDIContainer.self) private var appDI

  @Namespace private var segmentAnimation
  @State private var chatPanelWidth: CGFloat = DesignSystem.GroupFeed.chatPanelWidth

  @State private var vm = GroupFeedViewModel()
  @AppStorage(UserDefaultsKey.isPublicModeEnabled.rawValue)
  private var isPublicModeEnabled: Bool = false

  private let minChatWidth: CGFloat = DesignSystem.GroupFeed.minChatWidth
  private let maxChatWidth: CGFloat = DesignSystem.GroupFeed.maxChatWidth

  var body: some View {
    HStack(spacing: 0) {
      VStack(spacing: 0) {
        headerView
        feedContent
      }
      .frame(maxWidth: .infinity)

      /// Resizable Chat Panel (trailing)
      if vm.isChatVisible {
        resizableChatPanel
      }
    }
    .background(Color(nsColor: .windowBackgroundColor))
    .accessibilityIdentifier("groupFeedView")
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

      ChatPanelView(viewModel: vm)
        .frame(width: chatPanelWidth)
        .transition(.move(edge: .trailing))
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          withAnimation(.easeInOut(duration: 0.2)) {
            vm.isChatVisible = false
          }
        } label: {
          Image(systemName: "arrow.right.to.line")
        }
        .keyboardShortcut("t", modifiers: .command)
      }
    }
  }

  // MARK: - Header

  private var headerView: some View {
    HStack(spacing: 0) {
      Text(sessionStore.currentGroup?.name ?? "Group")
        .font(.title) // .title
        .fontWeight(.semibold)
        .foregroundStyle(.primary)

      Spacer()

      HStack(spacing: 16) {
        // User Avatars
        HStack(spacing: -10) {
          ForEach(sessionStore.groupMembers.prefix(3)) { member in
            DefaultAvatar(displayName: member.displayName, size: 32)
              .overlay(Circle().stroke(.white, lineWidth: 2))
          }

          if sessionStore.groupMembers.count > 3 {
            Text("+\(sessionStore.groupMembers.count - 3)")
              .font(.caption2)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)
              .frame(width: 32, height: 32)
              .background(Color.gray.opacity(0.1))
              .clipShape(Circle())
              .overlay(Circle().stroke(.white, lineWidth: 2))
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
    VStack(spacing: 0) {
      // Custom Segmented Control
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 0) {
          ForEach(sessionStore.groupMembers) { member in
            let isSelected = vm.selectedMemberId == member.id
            Text(member.displayName)
              .font(.subheadline)
              .fontWeight(isSelected ? .semibold : .regular)
              .foregroundStyle(isSelected ? .white : .primary)
              .padding(.vertical, 8)
              .padding(.horizontal, 16)
              .background {
                if isSelected {
                  RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue) // Accent color
                    .matchedGeometryEffect(id: "segment", in: segmentAnimation)
                }
              }
              .contentShape(Rectangle())
              .onTapGesture {
                withAnimation(.snappy) {
                  vm.selectedMemberId = member.id
                }
              }
          }
        }
        .padding(4)
        .background(Color(nsColor: .controlBackgroundColor)) // or .tertiarySystemFill
        .clipShape(RoundedRectangle(cornerRadius: 12))
      }
      .frame(maxWidth: .infinity, alignment: .leading) // Container leading alignment
      .padding(.horizontal, 24)
      .padding(.top, 12)
      .padding(.bottom, 6)

      // Selected member's todos
      if let memberId = vm.selectedMemberId,
         let member = sessionStore.groupMembers.first(where: { $0.id == memberId }) {
        ScrollView {
          GroupMemberSection(
            user: member,
            todos: (todoStore.todos[member.id] ?? []).map { ViewTodo(from: $0) },
          )
          .padding(24)
        }
      } else {
        Spacer()
      }
    }
    .toolbar {
      if !vm.isChatVisible {
        ToolbarItem(placement: .primaryAction) {
          Button {
            withAnimation(.easeInOut(duration: 0.2)) {
              vm.isChatVisible = true
            }
          } label: {
            Image(systemName: "bubble.left.and.bubble.right")
          }
          .keyboardShortcut("t", modifiers: .command)
        }
      }
    }
    .onAppear {
      if vm.selectedMemberId == nil {
        vm.selectedMemberId = sessionStore.groupMembers.first?.id
      }

      // Update Cache
      if let group = sessionStore.currentGroup {
        appDI.core.sidebarCacheUseCase.saveGroup(name: group.name, id: group.id)
      }
    }
    .task {
      guard sessionStore.isAuthenticated, !sessionStore.userId.isEmpty else { return }
      if isPublicModeEnabled {
        await refreshData()
      }
    }
    .onChange(of: isPublicModeEnabled) { _, isEnabled in
      if isEnabled {
        Task {
          await refreshData()
        }
      }
    }
    .onChange(of: sessionStore.currentGroup) { _, group in
      if let group {
        appDI.core.sidebarCacheUseCase.saveGroup(name: group.name, id: group.id)
      }
    }
  }

  private func refreshData() async {
    do {
      // 1. Sync local todos to server
      try await appDI.syncTodayTodosUseCase.run(for: sessionStore.userId, in: Date())

      // 2. Fetch latest data from server to update UI
      await todoStore.refresh(for: [sessionStore.userId])
    } catch {
      Log.error("Failed to sync/refresh in GroupFeed: \(error)", category: .data)
    }
  }
}

// MARK: - Group Member Section

private struct GroupMemberSection: View {
  let user: User
  let todos: [ViewTodo]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
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
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.bottom, 16)
  }
}

// MARK: - Chat Panel View

private struct ChatPanelView: View {
  @Environment(SessionStore.self) private var sessionStore
  @Environment(TodoStore.self) private var todoStore
  @Environment(MessageStore.self) private var messageStore
  @Bindable var viewModel: GroupFeedViewModel

  // Removed Photo Picker state for now as it's not supported by domain

  /// Messages grouped by date for display
  private var groupedMessages: [(date: Date, messages: [GroupMessage])] {
    Dictionary(grouping: messageStore.messages) { message in
      Calendar.current.startOfDay(for: message.createdAt)
    }
    .map { (date: $0.key, messages: $0.value.sorted { $0.createdAt < $1.createdAt }) }
    .sorted { $0.date < $1.date }
  }

  var body: some View {
    VStack(spacing: 0) {
      // Messages
      ScrollViewReader { proxy in
        ScrollView {
          LazyVStack(spacing: 16) {
            ForEach(groupedMessages, id: \.date) { group in
              // Date header
              Text(formatDateHeader(group.date))
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Capsule())
                .padding(.top, 10)

              ForEach(group.messages) { message in
                // Convert GroupMessage to ChatMessage for display
                let chatMsg = ViewGroupMessage(from: message, senderId: message.owner)
                let sender = viewModel.getMember(byId: message.owner, sessionStore: sessionStore)
                let viewUser = sender.map { ViewUser(from: $0) }

                HStack(alignment: .bottom, spacing: 2) {
                  if message.owner == sessionStore.userId {
                    Spacer()
                    Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                      .font(.caption2)
                      .foregroundStyle(.tertiary)
                    ChatMessageBubble(
                      message: chatMsg,
                      isMe: true,
                      user: viewUser,
                    )
                  } else {
                    ChatMessageBubble(
                      message: chatMsg,
                      isMe: false,
                      user: viewUser,
                    )
                    Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                      .font(.caption2)
                      .foregroundStyle(.tertiary)
                    Spacer()
                  }
                }
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

      // Input
      chatInput
    }
    .background(.ultraThinMaterial)
  }

  private func formatDateHeader(_ date: Date) -> String {
    DateHeaderFormatter.format(date)
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
