//
//  MainView.swift
//  TodoMate
//
//  Created by hs on 6/2/25.
//

import SimpleOverlaySystem
import SwiftUI

// MARK: - MainView

struct MainView: View {
  @Environment(AppDIContainer.self) private var container
  /// SessionStore 생성
  @State private var sessionStore: SessionStore

  init(container: AppDIContainer) {
    _sessionStore = State(initialValue: SessionStore(container: container))
  }

  var body: some View {
    OverlayContainer {
      MainContent(naviManager: .init(container: container))
        .environment(sessionStore)
    }
    .task {
      sessionStore.startListeningToAuthChanges()
    }
  }
}

// MARK: - MainContent

private struct MainContent: View {
  @Environment(AppDIContainer.self) private var container
  @State private var naviManager: NavigationManager

  init(naviManager: NavigationManager) {
    self.naviManager = naviManager
  }

  var body: some View {
    @Bindable var naviManager = naviManager

    NavigationSplitView(columnVisibility: $naviManager.columnVisibility) {
      SidebarView(selection: $naviManager.selection)
    } detail: {
      detailView
    }
    .navigationSplitViewStyle(.prominentDetail)
    .environment(naviManager)
  }

  @ViewBuilder
  private var detailView: some View {
    if let selection = naviManager.selection {
      switch selection {
      case .todo:
        switch naviManager.viewMode {
        case .board:
          BoardView(selection: .todo)
        case .calendar:
          CalendarView(selection: .todo)
        }

      case .memo:
        MemoView()

      case .settings:
        AuthenticatedView {
          SettingView()
        }

      case .group:
        AuthenticatedView {
          GroupFeedWrapperView(container: container)
        }
      }
    } else {
      unavailableView
    }
  }

  private var unavailableView: some View {
    ContentUnavailableView(
      "Select an Item",
      systemImage: "sidebar.left",
      description: Text("Choose a category from the sidebar"),
    )
  }
}

#Preview {
  MainView(container: .preview)
    .frame(width: 800, height: 600)
    .environment(AppDIContainer.preview)
    .environment(AppDIContainer.preview)
    .environment(TodoStore.preview)
}
