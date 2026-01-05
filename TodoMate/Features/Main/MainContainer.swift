//
//  MainContainer.swift
//  TodoMate
//
//  Root container view with navigation structure.
//
//  Created by agent on 1/5/26.
//

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
  @Environment(OverlayManager.self) private var overlayManager

  @State private var sidebarSelection: SidebarSelection? = .todo
  @State private var columnVisibility: NavigationSplitViewVisibility = .all
  @State private var viewMode: ContentViewMode = .board
  @State private var calendarDate = Date()
  @State private var selectedTask: ViewTodo?

  var body: some View {
    OverlayContainer {
      NavigationSplitView(columnVisibility: $columnVisibility) {
        NewSidebarView(selection: $sidebarSelection)
          .safeAreaInset(edge: .top) {
            Spacer().frame(height: 8)
          }
      } detail: {
        detailView
      }
      .toolbar {
        // Principal / Leading: Date & Task info + Navigation
        ToolbarItem(placement: .primaryAction) {
          if sidebarSelection == .todo, viewMode == .calendar {
            calendarHeader
              .padding(.horizontal)
          }
        }

        // Right side: View mode picker and add button
        ToolbarItemGroup(placement: .primaryAction) {
          Spacer()
          if sidebarSelection == .todo {
            viewModeToolbar
            addButton
          }
        }
      }
      .navigationSplitViewStyle(.prominentDetail)
      .task {
        await loadData()
      }
    }
  }

  private func loadData() async {
    // 1. Refresh Session (User & Group)
    await sessionStore.refresh()

    // 2. Refresh Todos (Self + Group Members)
    // Identify who we need to fetch todos for
    var todoUserIds = [sessionStore.userId]
    if !sessionStore.userGroupId.isEmpty {
      todoUserIds.append(contentsOf: sessionStore.userGroupIds)
    }
    let uniqueUserIds = Array(Set(todoUserIds))
    await todoStore.refresh(for: uniqueUserIds, currentUserId: sessionStore.userId)

    // 3. Refresh Memos (Self)
    await memoStore.refresh(for: [sessionStore.userId])

    // 4. Refresh Messages (Group)
    if !sessionStore.userGroupId.isEmpty {
      await messageStore.refresh(groupId: sessionStore.userGroupId)
    }
  }

  // MARK: - Detail View

  @ViewBuilder
  private var detailView: some View {
    if case .noGroups = sidebarSelection {
      GroupFeedNoGroupView()
    } else if sidebarSelection == .memo {
      MemoView()
    } else if sidebarSelection == .settings {
      SettingsView()
    } else if case .group = sidebarSelection {
      GroupFeedView()
    } else if let selection = sidebarSelection {
      switch viewMode {
      case .board:
        BoardView(selection: selection)
      case .calendar:
        CalendarContentView(
          selection: selection,
          currentDate: $calendarDate,
          selectedTask: $selectedTask,
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

  // MARK: - Calendar Navigation

  private var calendarHeader: some View {
    Text(calendarDate.formatted(.dateTime.year().month(.wide)))
      .font(.headline)
      .foregroundStyle(.primary)
      .fixedSize()
  }

  // MARK: - Toolbar Components

  private var viewModeToolbar: some View {
    Picker("View Mode", selection: $viewMode) {
      ForEach(ContentViewMode.allCases) { mode in
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
      overlayManager.presentSheet(editableTodo: newTodo) {
        TodoSheet(editableTodo: newTodo)
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
    .environment(OverlayManager())
}
