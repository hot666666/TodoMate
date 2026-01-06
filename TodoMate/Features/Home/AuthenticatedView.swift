//
//  AuthenticatedView.swift
//  TodoMate
//
//  Root container view with navigation structure.
//
//  Created by hs on 1/5/26.
//

import SimpleOverlaySystem
import SwiftUI

struct AuthenticatedView: View {
  @Environment(\.overlayManager) private var overlay
  @Environment(DIContainer.self) private var container
  @Environment(SessionStore.self) private var sessionStore
  @Environment(TodoStore.self) private var todoStore
  @Environment(MemoStore.self) private var memoStore
  @Environment(MessageStore.self) private var messageStore
  @State private var naviManager: NavigationManager
  @State private var calendarDate = Date()
  @State private var selectedTask: ViewTodo?

  init(naviManager: NavigationManager) {
    self.naviManager = naviManager
  }

  var body: some View {
    @Bindable var naviManager = naviManager
    NavigationSplitView(columnVisibility: $naviManager.columnVisibility) {
      SidebarView(selection: $naviManager.selection)
        .safeAreaInset(edge: .top) {
          Spacer().frame(height: 8)
        }
    } detail: {
      detailView
    }
    .toolbar {
      // Principal / Leading: Date & Task info + Navigation
      ToolbarItem(placement: .primaryAction) {
        if case .todo = naviManager.selection, naviManager.viewMode == .calendar {
          calendarHeader
            .padding(.horizontal)
        }
      }

      // Right side: View mode picker and add button
      ToolbarItemGroup(placement: .primaryAction) {
        Spacer()
        if case .todo = naviManager.selection {
          viewModeToolbar
          addButton
        }
      }
    }
    .navigationSplitViewStyle(.prominentDetail)
    .environment(naviManager)
  }

  // MARK: - Detail View

  @ViewBuilder
  private var detailView: some View {
    if let selection = naviManager.selection {
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
        switch naviManager.viewMode {
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
    @Bindable var naviManager = naviManager
    return Picker("View Mode", selection: $naviManager.viewMode) {
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
  OverlayContainer {
    AuthenticatedView(naviManager: .preview)
      .environment(DIContainer.preview)
      .environment(SessionStore.preview)
      .environment(TodoStore.preview)
      .environment(MemoStore.preview)
      .environment(MessageStore.preview)
  }
}
