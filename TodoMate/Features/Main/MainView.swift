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
  @Environment(OverlayManager.self) var overlayManager

  @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
  @State private var isMessageScreenPresented: Bool = false
  @State private var selectedScreen: Sidebar = .home
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

    case .syncWidget:
      guard syncTask == nil else { return }

      syncTask = Task {
        defer { syncTask = nil }
        await container.widgetSyncService.sync()
      }

    case .toggleSidebar:
      if columnVisibility == .detailOnly {
        columnVisibility = .all
      } else {
        columnVisibility = .detailOnly
      }
    }
  }
}

extension MainView {
  var body: some View {
    OverlayContainer {
      NavigationSplitView(columnVisibility: $columnVisibility) {
        List(Sidebar.allCases, selection: $selectedScreen) { screen in
          Text(screen.rawValue)
        }
      } detail: {
        selectedView
      }
      .inspector(isPresented: $isMessageScreenPresented) {
        MessageScreen()
          .inspectorColumnWidth(min: 300, ideal: 500)
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
      .onChange(of: scenePhase) { _, _ in
        Task { await perform(.syncWidget) }
      }
      .background(sidebarButton)
      .disabled(overlayManager.isPresented)
    }
  }

  @ViewBuilder
  private var selectedView: some View {
    switch selectedScreen {
    case .home:
      HomeScreen()
        .environment(refreshTrigger)
    case .profile:
      ProfileScreen()
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
    .keyboardShortcut("d", modifiers: .command)
  }

  private var messageButton: some View {
    Button("메시지", systemImage: "bubble.right") {
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
