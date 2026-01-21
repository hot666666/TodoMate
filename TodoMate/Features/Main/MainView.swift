//
//  MainView.swift
//  TodoMate
//
//  Created by hs on 6/2/25.
//

import SimpleOverlaySystem
import SwiftUI

struct MainView: View {
  @Environment(AppDIContainer.self) private var container
  @Environment(TodoBoardStore.self) private var todoBoardStore
  @Environment(MemoStore.self) private var memoStore

  @State private var naviManager: NavigationManager
  @State private var sessionStore: SessionStore

  init(container: AppDIContainer) {
    _naviManager = State(initialValue: NavigationManager(container: container))
    _sessionStore = State(initialValue: SessionStore(container: container))
  }

  var body: some View {
    OverlayContainer {
      splitView
        .environment(sessionStore)
        .environment(naviManager)
    }
    .onGlobalHotKey(.b, modifiers: [.command]) {
      toggleSidebar()
    }
    .task {
      await sessionStore.startListeningToAuthChanges()
    }
  }

  private var splitView: some View {
    NavigationSplitView(columnVisibility: $naviManager.columnVisibility) {
      Sidebar()
    } detail: {
      detailView
    }
    .navigationSplitViewStyle(.prominentDetail)
  }

  @ViewBuilder
  private var detailView: some View {
    if let selection = naviManager.selection {
      switch selection {
      case .settings:
        SettingView()

      case .todo:
        homeView

      case .memo:
        MemoView()

      case .group:
        AuthenticatedView {
          GroupFeedWrapperView(container: container)
        }
      }
    } else {
      unavailableView
    }
  }

  @ViewBuilder
  private var homeView: some View {
    switch naviManager.viewMode {
    case .board:
      BoardView()
    case .calendar:
      CalendarView(container: container.core)
    }
  }

  private var unavailableView: some View {
    ContentUnavailableView(
      "Select an Item",
      systemImage: "sidebar.left",
      description: Text("Choose a category from the sidebar"),
    )
  }

  private func toggleSidebar() {
    withAnimation {
      naviManager.columnVisibility =
        naviManager.columnVisibility == .all ? .detailOnly : .all
    }
  }
}

#Preview {
  MainView(container: .preview)
    .frame(width: 800, height: 600)
    .environment(AppDIContainer.preview)
    .environment(TodoStore.preview)
    .environment(MemoStore.preview)
}
