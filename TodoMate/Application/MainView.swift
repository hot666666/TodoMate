//
//  MainView.swift
//  TodoMate
//
//  Created by hs on 6/2/25.
//

import SimpleOverlaySystem
import SwiftUI

struct MainView: View {
  @Environment(CoreDIContainer.self) private var core

  var body: some View {
    OverlayContainer {
      MainContent(naviManager: .init(container: core))
    }
  }
}

private struct MainContent: View {
  @Environment(CoreDIContainer.self) private var core
  @Environment(SessionStore.self) private var sessionStore
  @Environment(\.overlayManager) private var overlay
  @Environment(\.scenePhase) private var scenePhase

  @State private var naviManager: NavigationManager

  init(naviManager: NavigationManager) {
    self.naviManager = naviManager
  }

  private var isOverlayPresented: Bool {
    !(overlay?.isEmpty ?? true)
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
    .onChange(of: scenePhase) { _, newPhase in
      if newPhase == .active {
        Task {
          // Refresh session/data if needed
          // Authentication check is now done at the view level (AuthenticatedView)
          // or implicitly by stores listening to auth changes.
          // sessionStore.refresh() might still be useful.
          await sessionStore.refresh()
        }
      }
    }
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
          GroupFeedView()
        }
      case .noGroups:
        AuthenticatedView {
          GroupFeedNoGroupView()
        }
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
  MainView()
    .frame(width: 800, height: 600)
    .environment(AppDIContainer.preview)
    .environment(CoreDIContainer.preview)
    .environment(SessionStore.preview)
    .environment(TodoStore.preview)
}
