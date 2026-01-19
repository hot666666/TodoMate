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
  /// NavigationManager 생성
  @State private var naviManager: NavigationManager

  init(container: AppDIContainer) {
    _sessionStore = State(initialValue: SessionStore(container: container))
    _naviManager = State(initialValue: NavigationManager(container: container))
  }

  var body: some View {
    OverlayContainer {
      MainContent(naviManager: naviManager)
        .environment(sessionStore)
        .environment(naviManager)
    }
    .task {
      sessionStore.startListeningToAuthChanges()
    }
    .onDisappear {
      sessionStore.cleanup()
    }
  }
}

// MARK: - MainContent

private struct MainContent: View {
  @Environment(AppDIContainer.self) private var container
  @Environment(\.overlayManager) private var overlay
  @State private var sidebarToken: HotKeyManager.RegistrationToken?

  @Bindable var naviManager: NavigationManager

  var body: some View {
    NavigationSplitView(columnVisibility: $naviManager.columnVisibility) {
      Sidebar(selection: $naviManager.selection)
    } detail: {
      detailView
    }
    .navigationSplitViewStyle(.prominentDetail)
    .onAppear {
      registerHotKeys()
    }
    .onDisappear {
      unregisterHotKeys()
    }
  }

  private func registerHotKeys() {
    // Command+B: Toggle Sidebar
    sidebarToken = container.core.hotKeyManager.register(
      key: .b, modifiers: [.command],
    ) { [weak naviManager] in
      Task { @MainActor in
        guard let naviManager else { return }
        withAnimation {
          naviManager.columnVisibility =
            naviManager.columnVisibility == .all ? .detailOnly : .all
        }
      }
    }
  }

  private func unregisterHotKeys() {
    if let token = sidebarToken {
      container.core.hotKeyManager.unregister(token)
    }
  }

  @ViewBuilder
  private var detailView: some View {
    if let selection = naviManager.selection {
      switch selection {
      case .settings:
        SettingView()

      case .todo:
        HomeView(container: container.core)

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
