//
//  AuthenticatedView.swift
//  TodoMate
//
//  Root container view with navigation structure.
//
//  Created by hs on 1/5/26.
//

import SwiftUI

struct AuthenticatedView: View {
  @Environment(SessionStore.self) private var sessionStore
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

  // MARK: - Detail View

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
        SettingView()
      case .group:
        GroupFeedView()
      case .noGroups:
        GroupFeedNoGroupView()
      }
    } else {
      ContentUnavailableView(
        "Select an Item",
        systemImage: "sidebar.left",
        description: Text("Choose a category from the sidebar"),
      )
    }
  }
}

#Preview {
  AuthenticatedView(naviManager: .preview)
    .environment(CoreDIContainer.preview)
    .environment(PublicDIContainer.preview)
    .environment(SessionStore.preview)
    .environment(TodoStore.preview)
    .environment(MemoStore.preview)
    .environment(MessageStore.preview)
}
