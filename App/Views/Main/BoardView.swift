//
//  BoardView.swift
//  TodoMate
//
//  Kanban-style board view for tasks
//

import SwiftUI

struct BoardView: View {
  let selection: SidebarSelection

  // Mock data - will be replaced with real data
  private let todoTasks: [Todo] = [
    Todo(
      id: "1",
      groupId: nil,
      owner: "user1",
      content: "Define Liquid Glass components",
      status: .todo,
      detail: "Create standard blurred backgrounds and border radius tokens.",
      date: Date(),
      tags: ["Design System"],
    ),
    Todo(
      id: "2",
      groupId: nil,
      owner: "user1",
      content: "Fix sidebar navigation bug",
      status: .todo,
      detail: "Dropdown menus are not closing when clicking outside.",
      date: Date(),
      tags: ["Urgent"],
    ),
  ]

  private let inProgressTasks: [Todo] = [
    Todo(
      id: "3",
      groupId: nil,
      owner: "user1",
      content: "Implement Dark Mode",
      status: .inProgress,
      detail: "Ensure all views have the dark mode variant.",
      date: Date(),
      tags: ["Frontend"],
    ),
  ]

  private let doneTasks: [Todo] = [
    Todo(
      id: "4",
      groupId: nil,
      owner: "user1",
      content: "Setup Project Repo",
      status: .done,
      detail: "",
      date: Date().addingTimeInterval(-86400),
      tags: ["DevOps"],
    ),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Date Header
      Text(Date().formatted(.dateTime.year().month().day().weekday(.wide)))
        .font(.title2)
        .fontWeight(.semibold)
        .padding(.horizontal)

      // Simple HStack - each column takes equal width via frame(maxWidth: .infinity)
      HStack(alignment: .top, spacing: 16) {
        TodoColumn(title: "To Do", count: todoTasks.count, color: .gray, tasks: todoTasks)
          .frame(maxWidth: .infinity)
        TodoColumn(
          title: "In Progress", count: inProgressTasks.count, color: DesignSystem.Colors.accentCyan,
          tasks: inProgressTasks,
        )
        .frame(maxWidth: .infinity)
        TodoColumn(
          title: "Done", count: doneTasks.count, color: DesignSystem.Colors.accentGreen,
          tasks: doneTasks,
        )
        .frame(maxWidth: .infinity)
      }
      .padding(.horizontal)
    }
    .padding(.top)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(Color(nsColor: .windowBackgroundColor))
    .accessibilityIdentifier("personalBoardView")
  }
}

// MARK: - Todo Column

private struct TodoColumn: View {
  let title: String
  let count: Int
  let color: Color
  let tasks: [Todo]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      columnHeader

      // Vertical scroll for cards within this column
      ScrollView(.vertical, showsIndicators: false) {
        LazyVStack(spacing: 12) {
          ForEach(tasks) { task in
            TaskCard(task: task)
          }
        }
      }
    }
  }

  private var columnHeader: some View {
    HStack {
      Circle()
        .fill(color)
        .frame(width: 10, height: 10)

      Text(title)
        .font(.headline)

      Text("\(count)")
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Color.secondary.opacity(0.1))
        .clipShape(.capsule)

      Spacer()

      Button {
        // More options
      } label: {
        Image(systemName: "ellipsis")
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)
    }
  }
}

#Preview {
  BoardView(selection: .todo)
}
