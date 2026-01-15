//
//  MainView.swift
//  TodoMate
//
//  Created by hs on 6/2/25.
//

import SimpleOverlaySystem
import SwiftUI
import WidgetKit

// MARK: - MainView

struct MainView: View {
  @Environment(AppDIContainer.self) private var container
  @Environment(\.scenePhase) private var scenePhase
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
    .onDisappear {
      sessionStore.cleanup()
    }
    .onChange(of: scenePhase) { _, newPhase in
      if newPhase != .active {
        WidgetCenter.shared.reloadAllTimelines()
      }
    }
  }
}

// MARK: - MainContent

private struct MainContent: View {
  @Environment(AppDIContainer.self) private var container
  @Environment(\.overlayManager) private var overlay
  @State private var naviManager: NavigationManager
  @State private var sidebarToken: HotKeyManager.RegistrationToken?

  init(naviManager: NavigationManager) {
    _naviManager = State(initialValue: naviManager)
  }

  var body: some View {
    @Bindable var naviManager = naviManager

    NavigationSplitView(columnVisibility: $naviManager.columnVisibility) {
      Sidebar(selection: $naviManager.selection)
    } detail: {
      detailView
    }
    .navigationSplitViewStyle(.prominentDetail)
    .environment(naviManager)
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
      case .todo:
        HomeView(naviManager: naviManager)

      case .memo:
        MemoView()

      case .settings:
        SettingView()

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
