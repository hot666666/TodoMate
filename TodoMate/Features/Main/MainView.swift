//
//  MainView.swift
//  Todo
//
//  Created by hs on 6/2/25.
//

import SwiftUI

struct MainView: View {
  @Environment(\.scenePhase) private var scenePhase
  @Environment(DIContainer.self) private var container
  @Environment(SessionStore.self) var sessionStore
  @Environment(MessageStore.self) var messageStore
  @Environment(TodoStore.self) var todoStore
  @Environment(MemoStore.self) var memoStore
  @Environment(OverlayManager.self) var overlayManager

  @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
  @State private var isMessageScreenPresented: Bool = false
  @State private var selectedSidebar: Sidebar = .profile
  @State private var refreshTrigger: RefreshTrigger = .init()
  @State private var syncTask: Task<Void, Never>?

  enum Action {
    case triggerRefresh
    case toggleMessageScreen
    case presentAddTodoSheet
    case presentCalendarScreen
    case refreshSession
    case syncWidget
    case toggleSidebar
  }

  @MainActor
  private func perform(_ action: Action) async {
    switch action {
    case .triggerRefresh:
      refreshTrigger.trigger()

    case .toggleMessageScreen:
      isMessageScreenPresented.toggle()

    case .presentAddTodoSheet:
      let selectedTodo = EditableTodo(owner: sessionStore.userId)
      overlayManager.presentSheet(editableTodo: selectedTodo) {
        TodoSheet(editableTodo: selectedTodo)
      }

    case .presentCalendarScreen:
      overlayManager.presentFullScreen {
        CalendarScreen(calendarVM: .init(container: container))
      }

    case .refreshSession:
      await sessionStore.refresh()
      // refresh 메서드는 로드->데이터패치/구독갱신
      await withTaskGroup(of: Void.self) { group in
        group.addTask {
          await memoStore.refresh(for: sessionStore.userGroupIds)
        }
        group.addTask {
          await todoStore.refresh(for: sessionStore.userGroupIds, currentUserId: sessionStore.userId)
        }
        group.addTask {
          await messageStore.refresh(groupId: sessionStore.userGroupId)
        }
      }

    case .syncWidget:
      guard syncTask == nil else { return }

      syncTask = Task {
        defer { syncTask = nil }
        await container.widgetSyncService.sync()
      }

    case .toggleSidebar:
      withAnimation {
        if columnVisibility == .detailOnly {
          columnVisibility = .all
        } else {
          columnVisibility = .detailOnly
        }
      }
    }
  }

  private func setupInitialSidebar() {
    selectedSidebar = .user(sessionStore.user)
  }
}

extension MainView {
  var body: some View {
    OverlayContainer {
      NavigationSplitView(columnVisibility: $columnVisibility) {
        SidebarList(item: $selectedSidebar)
          .transaction { $0.animation = nil }
      } detail: {
        selectedView
      }
      .inspector(isPresented: $isMessageScreenPresented) {
        MessageScreen()
          .inspectorColumnWidth(min: 300, ideal: 500)
      }
      .onChange(of: isMessageScreenPresented) { _, isPresented in
        if isPresented {
          messageStore.markAllAsRead()
        }
      }
      .toolbar {
        ToolbarItemGroup(placement: .primaryAction) {
          reloadButton
          Spacer()
          HStack(spacing: 8) {
            addTodoButton
            calendarButton
            messageButton
          }
        }
      }
      .task(id: refreshTrigger.value) {
        await perform(.refreshSession)
      }
      .background(sidebarButton)
      .disabled(overlayManager.isPresented)
      .onAppear {
        setupInitialSidebar()
      }
    }
  }

  @ViewBuilder
  private var selectedView: some View {
    switch selectedSidebar {
    case .profile:
      ProfileScreen()
    case let .user(user):
      if user.id == sessionStore.userId {
        MyUserScreen(user: user)
      } else {
        OtherUserScreen(user: user)
      }
    }
  }

  private var reloadButton: some View {
    Button("새로고침", systemImage: "arrow.clockwise") {
      Task { await perform(.triggerRefresh) }
    }
    .keyboardShortcut("r", modifiers: .command)
  }

  private var addTodoButton: some View {
    Button("새 할일", systemImage: "plus") {
      Task { await perform(.presentAddTodoSheet) }
    }
    .keyboardShortcut("n", modifiers: .command)
  }

  private var calendarButton: some View {
    Button("달력", systemImage: "calendar") {
      Task { await perform(.presentCalendarScreen) }
    }
    .keyboardShortcut("a", modifiers: .command)
  }

  private var messageButton: some View {
    Button("메시지", systemImage: messageStore.hasUnreadMessages ? "bubble.right.fill" : "bubble.right") {
      Task { await perform(.toggleMessageScreen) }
    }
    .keyboardShortcut("i", modifiers: .command)
  }

  private var sidebarButton: some View {
    Button("") {
      Task { await perform(.toggleSidebar) }
    }
    .keyboardShortcut("b", modifiers: .command)
    .hidden()
  }
}

#Preview {
  MainView()
    .environment(DIContainer.preview)
    .environment(SessionStore.preview)
    .environment(MessageStore.preview)
    .environment(TodoStore.preview)
    .environment(MemoStore.preview)
    .environment(OverlayManager())
}
