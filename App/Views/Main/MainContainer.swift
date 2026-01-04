//
//  MainContainer.swift
//  TodoMate
//
//  Created by agent on 1/3/26.
//

import SwiftUI

struct MainContainer: View {
  @Environment(AppDependencies.self) private var dependencies

  var body: some View {
    #if DEBUG
      // Bypass auth for development
      AuthenticatedView()
    #else
      if dependencies.authManager.isAuthenticated {
        AuthenticatedView()
      } else {
        AuthView()
      }
    #endif
  }
}

// MARK: - Authenticated View

private struct AuthenticatedView: View {
  @State private var sidebarSelection: SidebarSelection? = .todo
  @State private var columnVisibility: NavigationSplitViewVisibility = .all
  @State private var viewMode: ContentViewMode = .board
  @State private var showAddTaskOverlay = false
  @State private var calendarDate = Date()
  private let calendar = Calendar.current
  @State private var selectedTask: Todo?

  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      SidebarView(selection: $sidebarSelection)
        .safeAreaInset(edge: .top) {
          // Add spacing between traffic lights and first list item
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
    // TODO: - 달 이동 버튼 오버레이 구현하기
    Text(calendarDate.formatted(.dateTime.year().month(.wide)))
      .font(.headline)
      .foregroundStyle(.primary)
      .fixedSize() // Prevent truncation
  }

  private func moveMonth(by value: Int) {
    if let newDate = Calendar.current.date(byAdding: .month, value: value, to: calendarDate) {
      calendarDate = newDate
    }
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

// MARK: - Placeholder Views

struct ListView: View {
  let selection: SidebarSelection

  var body: some View {
    Text("List View - \(selection.title)")
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(nsColor: .windowBackgroundColor))
  }
}

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
      TextField("Ad description...", text: $description, axis: .vertical)
        .textFieldStyle(.plain)
        .lineLimit(3 ... 6)

      Spacer()

      // Actions
      HStack {
        Spacer()

        Button("Add Task") {
          // Add task logic
          isPresented = false
        }
        .keyboardShortcut(.defaultAction)
        .buttonStyle(.borderedProminent)
      }
    }
    .padding(24)
  }
}

#Preview {
  MainContainer()
    .environment(AppDependencies())
}
