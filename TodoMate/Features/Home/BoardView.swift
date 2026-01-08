//
//  BoardView.swift
//  TodoMate
//
//  Kanban-style board view for tasks
//
//  Created by agent on 1/5/26.
//

import SimpleOverlaySystem
import SwiftUI

// MARK: - Date Filter

enum DateFilter: String, CaseIterable {
  case today = "오늘"
  case lastWeek = "최근 1주"
  case lastMonth = "최근 1달"

  var dateRange: ClosedRange<Date> {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)
    let endOfToday = calendar.date(byAdding: .day, value: 1, to: today)!

    switch self {
    case .today:
      return today ... endOfToday
    case .lastWeek:
      let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
      return weekAgo ... endOfToday
    case .lastMonth:
      let monthAgo = calendar.date(byAdding: .month, value: -1, to: today)!
      return monthAgo ... endOfToday
    }
  }
}

// MARK: - Scroll Position

private enum BoardScrollPosition: String, Hashable {
  case leading
  case trailing
}

// MARK: - BoardView

struct BoardView: View {
  @Environment(TodoStore.self) private var todoStore
  @Environment(SessionStore.self) private var sessionStore
  @Environment(\.overlayManager) private var overlay
  let selection: NavigationDestination

  @State private var dateFilter: DateFilter = .today
  @State private var scrollPosition: BoardScrollPosition? = .leading

  // Computed properties to group tasks by status
  private var viewTodos: [ViewTodo] {
    let todos = todoStore.todos[sessionStore.userId] ?? []
    let range = dateFilter.dateRange
    return
      todos
        .filter { range.contains($0.date) }
        .map { ViewTodo(from: $0) }
        .sorted { $0.date > $1.date }
  }

  private func isToday(_ date: Date) -> Bool {
    Calendar.current.isDateInToday(date)
  }

  private var todoTasks: [ViewTodo] {
    viewTodos.filter { $0.status == .todo }
  }

  private var inProgressTasks: [ViewTodo] {
    viewTodos.filter { $0.status == .inProgress }
  }

  private var doneTasks: [ViewTodo] {
    viewTodos.filter { $0.status == .done }
  }

  private var inCompleteTasks: [ViewTodo] {
    viewTodos.filter { $0.status == .inComplete }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Date Header with Filter
      HStack {
        Text(Date().formatted(.dateTime.year().month().day().weekday(.wide)))
          .font(.title)
          .fontWeight(.semibold)

        Spacer()

        // Scroll Navigation Buttons
        HStack(spacing: 8) {
          Button {
            withAnimation(.smooth) {
              scrollPosition = .leading
            }
          } label: {
            Image(systemName: "chevron.left.2")
          }
          .disabled(scrollPosition == .leading)

          Button {
            withAnimation(.smooth) {
              scrollPosition = .trailing
            }
          } label: {
            Image(systemName: "chevron.right.2")
          }
          .disabled(scrollPosition == .trailing)
        }
        .buttonStyle(.borderless)
      }
      .padding(.horizontal)

      GeometryReader { proxy in
        let spacing: CGFloat = 16
        let horizontalMargin: CGFloat = 16
        let totalSpacing = spacing * 2 // 3 visible columns -> 2 spaces
        let visibleWidth = proxy.size.width - (horizontalMargin * 2)
        let columnWidth = floor((visibleWidth - totalSpacing) / 3)

        HStack(alignment: .top, spacing: spacing) {
          if scrollPosition == .leading {
            TodoColumn(
              title: "To Do",
              count: todoTasks.count,
              color: .gray,
              tasks: todoTasks,
              isToday: isToday,
              onTapTask: presentTodoSheet,
              onStatusClick: { task in cycleStatus(task) },
              onStatusChange: { task, status in updateTaskStatus(task, to: status) },
              onDropTask: { task in updateTaskStatus(task, to: .todo) },
            )
            .frame(width: columnWidth)
            .transition(.move(edge: .leading).combined(with: .opacity))
          }

          TodoColumn(
            title: "In Progress",
            count: inProgressTasks.count,
            color: DesignSystem.Colors.accentCyan,
            tasks: inProgressTasks,
            isToday: isToday,
            onTapTask: presentTodoSheet,
            onStatusClick: { task in cycleStatus(task) },
            onStatusChange: { task, status in updateTaskStatus(task, to: status) },
            onDropTask: { task in updateTaskStatus(task, to: .inProgress) },
          )
          .frame(width: columnWidth)

          TodoColumn(
            title: "Done",
            count: doneTasks.count,
            color: DesignSystem.Colors.accentGreen,
            tasks: doneTasks,
            isToday: isToday,
            onTapTask: presentTodoSheet,
            onStatusClick: { task in cycleStatus(task) },
            onStatusChange: { task, status in updateTaskStatus(task, to: status) },
            onDropTask: { task in updateTaskStatus(task, to: .done) },
          )
          .frame(width: columnWidth)

          if scrollPosition == .trailing {
            TodoColumn(
              title: "Incomplete",
              count: inCompleteTasks.count,
              color: DesignSystem.Colors.accentRed,
              tasks: inCompleteTasks,
              isToday: isToday,
              onTapTask: presentTodoSheet,
              onStatusClick: { task in cycleStatus(task) },
              onStatusChange: { task, status in updateTaskStatus(task, to: status) },
              onDropTask: { task in updateTaskStatus(task, to: .inComplete) },
            )
            .frame(width: columnWidth)
            .transition(.move(edge: .trailing).combined(with: .opacity))
          }
        }
        .padding(.horizontal, horizontalMargin)
      }
    }
    .background(Color(nsColor: .windowBackgroundColor))
    .accessibilityIdentifier("personalBoardView")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Menu {
          Picker("Date Filter", selection: $dateFilter) {
            ForEach(DateFilter.allCases, id: \.self) { filter in
              Text(filter.rawValue).tag(filter)
            }
          }
          .pickerStyle(.inline)
        } label: {
          Image(
            systemName: dateFilter == .today
              ? "line.3.horizontal.decrease.circle"
              : "line.3.horizontal.decrease.circle.fill",
          )
          .foregroundStyle(dateFilter == .today ? .secondary : DesignSystem.Colors.primary)
          .contentTransition(.symbolEffect(.replace))
        }
        .menuIndicator(.hidden)
      }

      HomeToolbarContent()
    }
  }

  // MARK: - Actions

  private func presentTodoSheet(for task: ViewTodo) {
    guard let userTodos = todoStore.todos[sessionStore.userId],
          let originalTodo = userTodos.first(where: { $0.id == task.id })
    else { return }

    let editableTodo = EditableTodo(from: originalTodo)
    overlay?.presentCentered(
      backdropOpacity: 0,
      offset: CGPoint(x: 0, y: -120),
    ) {
      TodoSheet(editableTodo: editableTodo)
    }
  }

  private func cycleStatus(_ task: ViewTodo) {
    let nextStatus: ViewTodoStatus =
      switch task.status {
      case .todo: .inProgress
      case .inProgress: .done
      case .done: .todo
      case .inComplete: .todo
      }
    updateTaskStatus(task, to: nextStatus)
  }

  private func updateTaskStatus(_ task: ViewTodo, to newStatus: ViewTodoStatus) {
    guard let userTodos = todoStore.todos[sessionStore.userId],
          let originalTodo = userTodos.first(where: { $0.id == task.id })
    else { return }

    var updatedTodo = originalTodo
    updatedTodo.status = newStatus.toDomainStatus()
    updatedTodo.updatedAt = Date()

    todoStore.update(updatedTodo, userId: sessionStore.userId)
  }
}

// MARK: - Todo Column

private struct TodoColumn: View {
  let title: String
  let count: Int
  let color: Color
  let tasks: [ViewTodo]
  let isToday: (Date) -> Bool
  let onTapTask: (ViewTodo) -> Void
  let onStatusClick: (ViewTodo) -> Void
  let onStatusChange: (ViewTodo, ViewTodoStatus) -> Void
  let onDropTask: (ViewTodo) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      columnHeader

      // Vertical scroll for cards within this column
      ScrollView(.vertical) {
        LazyVStack(spacing: 12) {
          ForEach(tasks) { task in
            TaskCard(
              task: task,
              onStatusClick: { onStatusClick(task) },
              onStatusChange: { status in onStatusChange(task, status) },
            )
            .opacity(isToday(task.date) ? 1.0 : 0.3)
            .draggable(task)
            .onTapGesture {
              onTapTask(task)
            }
          }
        }
      }
      .contentMargins(.bottom, 40, for: .scrollContent)
    }
    .dropDestination(for: ViewTodo.self) { items, _ in
      if let task = items.first {
        onDropTask(task)
        return true
      }
      return false
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
    }
  }
}

#Preview {
  BoardView(selection: .todo)
    .environment(TodoStore.preview)
    .environment(SessionStore.preview)
    .environment(OverlayManager())
}
