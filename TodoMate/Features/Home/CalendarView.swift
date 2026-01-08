//
//  CalendarView.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SimpleOverlaySystem
import SwiftUI

struct CalendarView: View {
  @Environment(TodoStore.self) private var todoStore
  @Environment(SessionStore.self) private var sessionStore
  @Environment(\.overlayManager) private var overlay
  let selection: NavigationDestination
  @State private var currentDate = Date()
  @State private var selectedTask: ViewTodo?

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
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        calendarHeader
      }
      HomeToolbarContent()
    }
  }

  // MARK: - Calendar Header

  private var calendarHeader: some View {
    HStack {
      Text(currentDate.formatted(.dateTime.month().year()))
        .font(.headline)

      HStack(spacing: 20) {
        Button {
          currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
        } label: {
          Image(systemName: "chevron.left")
            .fontWeight(.semibold)
        }

        Button {
          currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
        } label: {
          Image(systemName: "chevron.right")
            .fontWeight(.semibold)
        }
      }
    }
    .padding(.horizontal)
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
      let cellHeight = geometry.size.height / CGFloat(DesignSystem.Layout.calendarRowCount)

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
            onTapMore: { date, todos in
              presentDayTodoList(for: date, todos: todos)
            },
          )
          .frame(minHeight: 100, maxHeight: .infinity, alignment: .top)
          .frame(height: cellHeight)
        }
      }
    }
  }

  // MARK: - Logic

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
    let totalDays = DesignSystem.Layout.calendarRowCount * 7
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
    overlay?.presentCentered(
      backdropOpacity: 0,
      offset: CGPoint(x: 0, y: -120),
    ) {
      TodoSheet(editableTodo: editableTodo)
    }
  }

  private func presentDayTodoList(for date: Date, todos: [ViewTodo]) {
    overlay?.presentCentered(
      backdropOpacity: 0,
    ) {
      DayTodoListView(
        date: date,
        todos: todos,
        onTapTodo: { task in
          overlay?.dismissTop()
          presentTodoSheet(for: task)
        },
      )
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
  let onTapMore: (Date, [ViewTodo]) -> Void

  private let calendar = Calendar.current

  private var isCurrentMonth: Bool {
    calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
  }

  private var isToday: Bool {
    calendar.isDateInToday(date)
  }

  var body: some View {
    GeometryReader { geometry in
      let availableHeight = geometry.size.height - DesignSystem.Layout.calendarCellHeaderHeight
      let itemHeight = DesignSystem.Layout.calendarCellItemHeight
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
            Button {
              onTapMore(date, tasks)
            } label: {
              Text("+\(tasks.count - visibleCount) more")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            }
            .buttonStyle(.plain)
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
  CalendarView(selection: .todo)
    .environment(NavigationManager.preview)
    .environment(TodoStore.preview)
    .environment(SessionStore.preview)
    .environment(MemoStore.preview)
    .environment(MessageStore.preview)
}
