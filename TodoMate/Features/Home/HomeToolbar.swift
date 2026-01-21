//
//  HomeToolbar.swift
//  TodoMate
//
//  Shared toolbar components for Home views (Board/Calendar)
//
//  Created by agent on 1/7/26.
//

import SimpleOverlaySystem
import SwiftUI

/// Common toolbar content for Home views (ViewModePicker + AddButton)
struct HomeToolbarContent: ToolbarContent {
  var body: some ToolbarContent {
    ToolbarItemGroup(placement: .primaryAction) {
      Spacer()
    }
    ToolbarItemGroup(placement: .primaryAction) {
      TodoViewModePicker()
    }
    ToolbarItemGroup(placement: .primaryAction) {
      AddTodoButton()
    }
  }
}

/// Toolbar containing view mode picker and add button for Todo views
struct TodoViewModePicker: View {
  @Environment(NavigationManager.self) private var naviManager

  var body: some View {
    HStack {
      Picker("View Mode", selection: Bindable(naviManager).viewMode) {
        ForEach(HomeMode.allCases) { mode in
          Image(systemName: mode.systemImage)
            .tag(mode)
            .accessibilityIdentifier("viewMode_\(mode.rawValue)")
        }
      }
      .pickerStyle(.segmented)
      .labelsHidden()
      .accessibilityIdentifier("viewModePicker")
    }
  }
}

/// Add button that opens TodoSheet for creating new todos
struct AddTodoButton: View {
  @Environment(\.overlayManager) private var overlay
  @Environment(SessionStore.self) private var sessionStore

  private func action() {
    let newTodo = EditableTodo(owner: sessionStore.userId)
    overlay?.presentCentered(
      id: OverlayIDs.todoSheet,
      backdropOpacity: 0,
      offset: CGPoint(x: 0, y: -120),
    ) {
      TodoSheet(editableTodo: newTodo)
    }
  }

  var body: some View {
    Button {
      action()
    } label: {
      Image(systemName: "plus")
    }
    .keyboardShortcut("n", modifiers: .command)
    .accessibilityIdentifier("addTaskButton")
  }
}
