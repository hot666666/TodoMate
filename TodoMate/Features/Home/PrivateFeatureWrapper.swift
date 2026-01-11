//
//  PrivateFeatureWrapper.swift
//  TodoMate
//
//  Created by agent on 1/11/26.
//

import SwiftUI

/// Wraps the 'Offline' or 'Private' mode of the application.
/// This view is active when isPublicModeEnabled is false.
struct PrivateFeatureWrapper: View {
  let core: CoreDIContainer

  @State private var naviManager: NavigationManager

  init(core: CoreDIContainer) {
    self.core = core
    _naviManager = State(initialValue: NavigationManager(container: core))
  }

  var body: some View {
    PrivateContentView(naviManager: naviManager)
      .environment(PrivateTodoStore(container: core)) // Inject Private Store if not already injected at App level
      .environment(SessionStore.local)
    // Note: PrivateTodoStore is also injected in TodoMateApp, but ensuring it's available here is good.
    // However, if we want single source of truth, we should rely on Environment.
    // TodoMateApp already injects PrivateTodoStore.
  }
}

private struct PrivateContentView: View {
  @State var naviManager: NavigationManager

  var body: some View {
    @Bindable var naviManager = naviManager

    NavigationSplitView(columnVisibility: $naviManager.columnVisibility) {
      PrivateSidebarView(selection: $naviManager.selection)
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
      case .settings:
        // Reuse SettingView? Check if it depends on Public Stores.
        // Assuming SettingView might need refactoring too, but for now placeholder or SettingView.
        Text("Settings (Offline)")
      default:
        ContentUnavailableView(
          "Coming Soon",
          systemImage: "hourglass",
          description: Text("This feature is not available in Offline Mode."),
        )
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
