//
//  HomeView.swift
//  TodoMate
//
//  Created by hs on 1/22/26.
//

import SimpleOverlaySystem
import SwiftUI

struct HomeView: View {
  @Environment(AppDIContainer.self) private var container
  @Environment(NavigationManager.self) private var naviManager
  @Environment(SessionStore.self) private var sessionStore
  @Environment(\.overlayManager) private var overlay

  var body: some View {
    Group {
      switch naviManager.viewMode {
      case .board:
        BoardView()
      case .calendar:
        CalendarView(container: container.core)
      }
    }
    .toolbar { toolbarContent }
    .accessibilityIdentifier("homeView")
  }

  // MARK: - Toolbar

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarSpacer(.flexible)
    ToolbarItem(placement: .primaryAction) {
      viewModePicker
    }
    ToolbarItem(placement: .primaryAction) {
      addButton
    }
  }

  private var viewModePicker: some View {
    Picker("View Mode", selection: Bindable(naviManager).viewMode) {
      ForEach(HomeMode.allCases) { mode in
        Image(systemName: mode.systemImage)
          .tag(mode)
          .accessibilityIdentifier("viewMode_\(mode.rawValue)")
      }
    }
    .pickerStyle(.segmented)
    .labelsHidden()
    // ⌘T: 뷰 모드 전환 (Board ↔ Calendar)
    .hiddenKeyboardShortcut("t", modifiers: .command) {
      withAnimation {
        naviManager.viewMode = naviManager.viewMode == .board ? .calendar : .board
      }
    }
    .accessibilityIdentifier("viewModePicker")
  }

  private var addButton: some View {
    Button {
      let newTodo = EditableTodo(owner: sessionStore.userId)
      overlay?.presentCentered(
        id: OverlayIDs.todoSheet,
        backdropOpacity: 0,
        offset: CGPoint(x: 0, y: -120),
      ) {
        TodoSheet(editableTodo: newTodo)
      }
    } label: {
      Image(systemName: "plus")
    }
    .keyboardShortcut("n", modifiers: .command)
    .accessibilityIdentifier("addTaskButton")
  }
}
