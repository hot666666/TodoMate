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
          .font(.title2)
          .fontWeight(.semibold)

        // Filter Menu - icon only, right next to date
        Menu {
          ForEach(DateFilter.allCases, id: \.self) { filter in
            Button {
              dateFilter = filter
            } label: {
              if filter == dateFilter {
                Label(filter.rawValue, systemImage: "checkmark")
              } else {
                Text(filter.rawValue)
              }
            }
          }
        } label: {
          Image(systemName: "line.3.horizontal.decrease.circle")
            .font(.title3)
            .foregroundStyle(dateFilter == .today ? .secondary : DesignSystem.Colors.primary)
            .symbolEffect(.pulse, options: .repeat(1), isActive: dateFilter != .today)
        }
        .menuStyle(.borderlessButton)

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

      // Horizontal scroll with 4 columns
      ScrollView(.horizontal) {
        HStack(alignment: .top, spacing: 16) {
          TodoColumn(
            title: "To Do",
            count: todoTasks.count,
            color: .gray,
            tasks: todoTasks,
            isToday: isToday,
            onTapTask: presentTodoSheet,
            onStatusClick: { task in cycleStatus(task) },
            onStatusRightClick: { task in updateTaskStatus(task, to: .inComplete) },
            onDropTask: { task in updateTaskStatus(task, to: .todo) },
          )
          .containerRelativeFrame(.horizontal, count: 3, span: 1, spacing: 16)
          .id(BoardScrollPosition.leading)

          TodoColumn(
            title: "In Progress",
            count: inProgressTasks.count,
            color: DesignSystem.Colors.accentCyan,
            tasks: inProgressTasks,
            isToday: isToday,
            onTapTask: presentTodoSheet,
            onStatusClick: { task in cycleStatus(task) },
            onStatusRightClick: { task in updateTaskStatus(task, to: .inComplete) },
            onDropTask: { task in updateTaskStatus(task, to: .inProgress) },
          )
          .containerRelativeFrame(.horizontal, count: 3, span: 1, spacing: 16)

          TodoColumn(
            title: "Done",
            count: doneTasks.count,
            color: DesignSystem.Colors.accentGreen,
            tasks: doneTasks,
            isToday: isToday,
            onTapTask: presentTodoSheet,
            onStatusClick: { task in cycleStatus(task) },
            onStatusRightClick: { task in updateTaskStatus(task, to: .inComplete) },
            onDropTask: { task in updateTaskStatus(task, to: .done) },
          )
          .containerRelativeFrame(.horizontal, count: 3, span: 1, spacing: 16)

          TodoColumn(
            title: "Incomplete",
            count: inCompleteTasks.count,
            color: DesignSystem.Colors.accentRed,
            tasks: inCompleteTasks,
            isToday: isToday,
            onTapTask: presentTodoSheet,
            onStatusClick: { task in cycleStatus(task) },
            onStatusRightClick: { task in updateTaskStatus(task, to: .inComplete) },
            onDropTask: { task in updateTaskStatus(task, to: .inComplete) },
          )
          .containerRelativeFrame(.horizontal, count: 3, span: 1, spacing: 16)
          .id(BoardScrollPosition.trailing)
        }
        .scrollTargetLayout()
        .padding(.horizontal)
      }
      .scrollTargetBehavior(.viewAligned)
      .scrollPosition(id: $scrollPosition, anchor: .leading)
      .scrollIndicators(.hidden)
    }
    .padding(.top)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(Color(nsColor: .windowBackgroundColor))
    .accessibilityIdentifier("personalBoardView")
    .toolbar {
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
  let onStatusRightClick: (ViewTodo) -> Void
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
              onStatusRightClick: { onStatusRightClick(task) },
            )
            .opacity(isToday(task.date) ? 1.0 : 0.65)
            .draggable(task)
            .onTapGesture {
              onTapTask(task)
            }
          }
        }
      }
      .scrollIndicators(.hidden)
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
