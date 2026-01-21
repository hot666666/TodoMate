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
  // MARK: - Environment

  @Environment(SessionStore.self) private var sessionStore
  @Environment(TodoStore.self) private var todoStore
  @Environment(MessageStore.self) private var messageStore
  @Environment(AppDIContainer.self) private var appDI

  // MARK: - State

  @State private var chatPanelWidth: CGFloat = DesignSystem.GroupFeed.chatPanelWidth
  @State private var vm = GroupFeedViewModel()
  @AppStorage(UserDefaultsKey.isPublicModeEnabled.rawValue)
  private var isPublicModeEnabled: Bool = false

  // MARK: - Properties

  private let minChatWidth: CGFloat = DesignSystem.GroupFeed.minChatWidth
  private let maxChatWidth: CGFloat = DesignSystem.GroupFeed.maxChatWidth

  // MARK: - Body

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

      ChatPanel(viewModel: vm)
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
    PageHeader(title: sessionStore.currentGroup?.name ?? "Group") {
      HStack(spacing: 16) {
        AvatarPile(members: sessionStore.groupMembers)

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
  }

  private var feedContent: some View {
    VStack(spacing: 0) {
      // Custom Segmented Control
      ScrollableSegmentedControl(
        items: sessionStore.groupMembers,
        selection: $vm.selectedMemberId,
        label: { $0.displayName },
      )
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 24)
      .padding(.top, 12)
      .padding(.bottom, 6)

      // Selected member's todos
      if let memberId = vm.selectedMemberId,
         let member = sessionStore.groupMembers.first(where: { $0.id == memberId }) {
        ScrollView {
          GroupMemberSection(
            user: member,
            todos: todoStore.todos[member.id] ?? [],
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
    .task(id: isPublicModeEnabled) {
      guard isPublicModeEnabled else { return }
      guard sessionStore.isAuthenticated, !sessionStore.userId.isEmpty else { return }
      await refreshData()
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
  let todos: [Todo]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      if todos.isEmpty {
        ContentUnavailableView(
          "No Tasks Shared",
          systemImage: "circle.dashed",
          description: Text("This member hasn't shared any tasks yet"),
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

#Preview {
  GroupFeedView()
    .environment(SessionStore.preview)
    .environment(TodoStore.preview)
    .environment(MessageStore.preview)
}
