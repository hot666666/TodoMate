//
//  CalendarContentView.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SwiftUI

struct CalendarContentView: View {
  @Environment(TodoStore.self) private var todoStore
  @Environment(SessionStore.self) private var sessionStore
  @Environment(OverlayManager.self) private var overlayManager
  let selection: SidebarSelection
  @Binding var currentDate: Date
  @Binding var selectedTask: ViewTodo?

  private let calendar = Calendar.current
  private let daysOfWeek = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

  // Grid columns
  private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

  // Convert store todos to view todos
  private var viewTodos: [ViewTodo] {
    let todos = todoStore.todos[sessionStore.userId] ?? []
    return todos.map { ViewTodo(from: $0) }
  }

  var body: some View {
    VStack(spacing: 0) {
      weekdayHeader
      calendarGrid
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(nsColor: .windowBackgroundColor))
    .accessibilityIdentifier("personalCalendarView")
  }

  // MARK: - Weekday Header

  private var weekdayHeader: some View {
    LazyVGrid(columns: columns, spacing: 0) {
      ForEach(daysOfWeek, id: \.self) { day in
        Text(day)
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
          .background(Color.secondary.opacity(0.05))
      }
    }
    .overlay(Divider(), alignment: .bottom)
  }

  // MARK: - Grid

  private var calendarGrid: some View {
    GeometryReader { geometry in
      let days = daysInMonth()
      let cellHeight = geometry.size.height / CGFloat(LayoutConstants.rowCount)

      LazyVGrid(columns: columns, spacing: 0) {
        ForEach(days, id: \.self) { date in
          CalendarCell(
            date: date,
            currentMonth: currentDate,
            tasks: tasksForDate(date),
            selectedTask: $selectedTask,
            onDrop: { task in
              moveTask(task, to: date)
            },
            onTapTask: { task in
              presentTodoSheet(for: task)
            },
          )
          .frame(minHeight: 100, maxHeight: .infinity, alignment: .top)
          .frame(height: cellHeight)
        }
      }
    }
  }

  // MARK: - Logic

  private enum LayoutConstants {
    static let rowCount = 6
  }

  private func daysInMonth() -> [Date] {
    guard let monthInterval = calendar.dateInterval(of: .month, for: currentDate) else {
      return []
    }
    let monthStart = monthInterval.start

    // Calculate start offset (previous month days)
    let weekday = calendar.component(.weekday, from: monthStart)
    let startOffset = weekday - 1 // Sunday is 1

    guard
      let startDisplayDate = calendar.date(
        byAdding: .day, value: -startOffset, to: monthStart,
      )
    else { return [] }

    // Always 42 days (6 rows * 7 cols) to keep layout stable
    let totalDays = LayoutConstants.rowCount * 7
    return (0 ..< totalDays).compactMap { dayOffset in
      calendar.date(byAdding: .day, value: dayOffset, to: startDisplayDate)
    }
  }

  private func tasksForDate(_ date: Date) -> [ViewTodo] {
    viewTodos.filter { calendar.isDate($0.date, inSameDayAs: date) }
  }

  private func moveTask(_ task: ViewTodo, to date: Date) {
    guard let userTodos = todoStore.todos[sessionStore.userId],
          let originalTodo = userTodos.first(where: { $0.id == task.id })
    else { return }

    var updatedTodo = originalTodo
    updatedTodo.date = date.startOfDay
    updatedTodo.updatedAt = Date()

    todoStore.update(updatedTodo, userId: sessionStore.userId)
  }

  private func presentTodoSheet(for task: ViewTodo) {
    guard let userTodos = todoStore.todos[sessionStore.userId],
          let originalTodo = userTodos.first(where: { $0.id == task.id })
    else { return }

    let editableTodo = EditableTodo(from: originalTodo)
    overlayManager.presentSheet(editableTodo: editableTodo) {
      TodoSheet(editableTodo: editableTodo)
    }
  }
}

// MARK: - Calendar Cell

struct CalendarCell: View {
  let date: Date
  let currentMonth: Date
  let tasks: [ViewTodo]
  @Binding var selectedTask: ViewTodo?
  let onDrop: (ViewTodo) -> Void
  let onTapTask: (ViewTodo) -> Void

  private let calendar = Calendar.current

  private enum Metrics {
    static let headerHeight: CGFloat = 30.0
    static let itemHeight: CGFloat = 26.0
  }

  private var isCurrentMonth: Bool {
    calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
  }

  private var isToday: Bool {
    calendar.isDateInToday(date)
  }

  var body: some View {
    GeometryReader { geometry in
      let availableHeight = geometry.size.height - Metrics.headerHeight
      let itemHeight = Metrics.itemHeight
      let maxItems = max(0, Int(availableHeight / itemHeight))
      let showMore = tasks.count > maxItems
      let visibleCount = showMore ? max(0, maxItems - 1) : tasks.count

      VStack(alignment: .leading, spacing: 4) {
        // Date Number
        Text("\(calendar.component(.day, from: date))")
          .font(.system(size: 14, weight: isToday ? .bold : .medium))
          .foregroundStyle(isToday ? .primary : (isCurrentMonth ? .primary : .secondary))
          .opacity(isCurrentMonth ? 1 : 0.4)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(6)

        // Tasks
        VStack(alignment: .leading, spacing: 2) {
          ForEach(tasks.prefix(visibleCount)) { task in
            TaskCard(task: task, style: .compact)
              .draggable(task)
              .onTapGesture {
                onTapTask(task)
              }
              .opacity(
                selectedTask?.id == task.id
                  ? 1.0 : (selectedTask == nil ? 1.0 : 0.6))
          }

          if showMore {
            Text("+\(tasks.count - visibleCount) more")
              .font(.caption2)
              .foregroundStyle(.secondary)
              .padding(.horizontal, 4)
          }
        }
        .padding(.horizontal, 2)

        Spacer(minLength: 0)
      }
    }
    .background(
      Rectangle()
        .stroke(Color.secondary.opacity(0.1), lineWidth: 0.5),
    )
    .background(isToday ? Color.blue.opacity(0.05) : Color.clear)
    .dropDestination(for: ViewTodo.self) { droppedTasks, _ in
      if let task = droppedTasks.first {
        onDrop(task)
        return true
      }
      return false
    }
  }
}

#Preview {
  CalendarContentView(
    selection: .todo,
    currentDate: .constant(Date()),
    selectedTask: .constant(nil),
  )
  .environment(TodoStore.preview)
  .environment(SessionStore.preview)
  .environment(OverlayManager())
}
