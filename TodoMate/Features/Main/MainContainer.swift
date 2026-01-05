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
  @Environment(OverlayManager.self) private var overlayManager

  @State private var sidebarSelection: SidebarSelection? = .todo
  @State private var columnVisibility: NavigationSplitViewVisibility = .all
  @State private var viewMode: ContentViewMode = .board
  @State private var showAddTaskOverlay = false
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
      .overlay {
        if showAddTaskOverlay {
          AddTaskOverlay(isPresented: $showAddTaskOverlay)
        }
      }
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
      showAddTaskOverlay = true
    } label: {
      Image(systemName: "plus")
    }
    .keyboardShortcut("n", modifiers: .command)
    .accessibilityIdentifier("addTaskButton")
  }
}

// MARK: - Add Task Overlay

struct AddTaskOverlay: View {
  @Binding var isPresented: Bool

  var body: some View {
    ZStack {
      Color.black.opacity(0.3)
        .ignoresSafeArea()
        .onTapGesture {
          isPresented = false
        }

      AddTaskSheet(isPresented: $isPresented)
        .frame(width: 500)
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: 16))
        .shadow(radius: 20)
    }
  }
}

struct AddTaskSheet: View {
  @Environment(SessionStore.self) private var sessionStore
  @Environment(TodoStore.self) private var todoStore
  @Binding var isPresented: Bool
  @State private var title = ""
  @State private var description = ""

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      // Header
      HStack {
        Text("New Task")
          .font(.title2.bold())
        Spacer()
        Button {
          isPresented = false
        } label: {
          Image(systemName: "xmark.circle.fill")
            .font(.title2)
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
      }

      // Title input
      TextField("Task title", text: $title)
        .textFieldStyle(.plain)
        .font(.title3)

      Divider()

      // Description
      TextField("Add description...", text: $description, axis: .vertical)
        .textFieldStyle(.plain)
        .lineLimit(3 ... 6)

      Spacer()

      // Actions
      HStack {
        Spacer()

        Button("Add Task") {
          let newTodo = Todo(
            owner: sessionStore.userId,
            content: title,
            detail: description,
          )
          todoStore.add(newTodo, userId: sessionStore.userId)
          isPresented = false
        }
        .keyboardShortcut(.defaultAction)
        .buttonStyle(.borderedProminent)
        .disabled(title.isEmpty)
      }
    }
    .padding(24)
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
