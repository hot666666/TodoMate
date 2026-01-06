//
//  MainContainer.swift
//  TodoMate
//
//  Root container view with navigation structure.
//
//  Created by agent on 1/5/26.
//

import SimpleOverlaySystem
import SwiftUI

struct MainContainer: View {
  var body: some View {
    AuthenticatedView()
  }
}

// MARK: - Authenticated View

private struct AuthenticatedView: View {
  @Environment(DIContainer.self) private var container
  @Environment(SessionStore.self) private var sessionStore
  @Environment(TodoStore.self) private var todoStore
  @Environment(MemoStore.self) private var memoStore
  @Environment(MessageStore.self) private var messageStore
  @Environment(\.overlayManager) private var overlay

  @State private var navigator = NavigationManager()
  @State private var calendarDate = Date()
  @State private var selectedTask: ViewTodo?

  var body: some View {
    NavigationSplitView(columnVisibility: $navigator.columnVisibility) {
      SidebarView(selection: $navigator.selection)
        .safeAreaInset(edge: .top) {
          Spacer().frame(height: 8)
        }
    } detail: {
      detailView
    }
    .toolbar {
      // Principal / Leading: Date & Task info + Navigation
      ToolbarItem(placement: .primaryAction) {
        if case .todo = navigator.selection, navigator.viewMode == .calendar {
          calendarHeader
            .padding(.horizontal)
        }
      }

      // Right side: View mode picker and add button
      ToolbarItemGroup(placement: .primaryAction) {
        Spacer()
        if case .todo = navigator.selection {
          viewModeToolbar
          addButton
        }
      }
    }
    .navigationSplitViewStyle(.prominentDetail)
    .environment(navigator)
  }

  // MARK: - Detail View

  @ViewBuilder
  private var detailView: some View {
    if let selection = navigator.selection {
      switch selection {
      case .noGroups:
        GroupFeedNoGroupView()
      case .memo:
        MemoView()
      case .settings:
        SettingView()
      case .group:
        GroupFeedView()
      case .todo:
        switch navigator.viewMode {
        case .board:
          BoardView(selection: .todo)
        case .calendar:
          CalendarView(
            selection: .todo,
            currentDate: $calendarDate,
            selectedTask: $selectedTask,
          )
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

  private var calendarHeader: some View {
    HStack(spacing: 16) {
      Text(calendarDate.formatted(.dateTime.month().year()))
        .font(.headline)

      HStack(spacing: 20) {
        Button {
          withAnimation {
            calendarDate =
              Calendar.current.date(byAdding: .month, value: -1, to: calendarDate) ?? calendarDate
          }
        } label: {
          Image(systemName: "chevron.left")
            .fontWeight(.semibold)
        }

        Button {
          withAnimation {
            calendarDate =
              Calendar.current.date(byAdding: .month, value: 1, to: calendarDate) ?? calendarDate
          }
        } label: {
          Image(systemName: "chevron.right")
            .fontWeight(.semibold)
        }
      }
    }
  }

  private var viewModeToolbar: some View {
    Picker("View Mode", selection: $navigator.viewMode) {
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

  private var addButton: some View {
    Button {
      let newTodo = EditableTodo(owner: sessionStore.userId)
      // Example usage of SimpleOverlaySystem
      overlay?.presentCentered {
        TodoSheet(editableTodo: newTodo)
          .environment(container)
          .environment(sessionStore)
          .environment(todoStore)
          .environment(memoStore)
          .environment(messageStore)
      }
    } label: {
      Image(systemName: "plus")
    }
    .keyboardShortcut("n", modifiers: .command)
    .accessibilityIdentifier("addTaskButton")
  }
}

#Preview {
  MainContainer()
    .environment(DIContainer.preview)
    .environment(SessionStore.preview)
    .environment(TodoStore.preview)
    .environment(MemoStore.preview)
    .environment(MessageStore.preview)
  // .environment(SimpleOverlay.mock) // If mock exists
}
