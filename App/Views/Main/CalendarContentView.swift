//
//  CalendarContentView.swift
//  TodoMate
//
//  Created by agent on 1/3/26.
//

import SwiftUI

struct CalendarContentView: View {
  let selection: SidebarSelection
  @Binding var currentDate: Date
  @Binding var selectedTask: Todo?
  @State private var tasks: [Todo] = [] // This would ideally come from a data source

  private let calendar = Calendar.current
  private let daysOfWeek = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

  // Grid columns
  private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

  // Mock data for preview/development
  init(selection: SidebarSelection, currentDate: Binding<Date>, selectedTask: Binding<Todo?>) {
    self.selection = selection
    _currentDate = currentDate
    _selectedTask = selectedTask
    // Initialize with some mock data if needed, or rely on onAppear
  }

  var body: some View {
    VStack(spacing: 0) {
      weekdayHeader
      calendarGrid
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(nsColor: .windowBackgroundColor)) // Matches CSS "bg-white/30 dark:bg-black/20" roughly
    .onAppear {
      loadMockTasks()
    }
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
      let cellHeight = geometry.size.height / 6 // 6 rows for 42 days

      LazyVGrid(columns: columns, spacing: 0) {
        ForEach(days, id: \.self) { date in
          CalendarCell(
            date: date,
            currentMonth: currentDate,
            tasks: tasksForDate(date),
            cellHeight: cellHeight,
            selectedTask: $selectedTask,
            onDrop: { task in
              moveTask(task, to: date)
            },
          )
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
    return (0 ..< 42).compactMap { dayOffset in
      calendar.date(byAdding: .day, value: dayOffset, to: startDisplayDate)
    }
  }

  private func tasksForDate(_ date: Date) -> [Todo] {
    tasks.filter { calendar.isDate($0.date, inSameDayAs: date) }
  }

  private func moveTask(_ task: Todo, to date: Date) {
    if let index = tasks.firstIndex(where: { $0.id == task.id }) {
      var updatedTask = task
      updatedTask.date = date
      tasks[index] = updatedTask
    }
  }

  private func loadMockTasks() {
    // Load some dummy data matching the reference
    let today = Date()
    tasks = [
      Todo(
        id: "1", groupId: nil, owner: "u1", content: "National Foundation", status: .todo,
        detail: "", date: today, tags: ["Design System"],
      ), // Purple
      Todo(
        id: "2", groupId: nil, owner: "u1", content: "Meeting with client", status: .todo,
        detail: "", date: today, tags: ["Frontend"],
      ), // Blue

      Todo(
        id: "3", groupId: nil, owner: "u1", content: "Grocery Run", status: .todo,
        detail: "", date: calendar.date(byAdding: .day, value: 1, to: today)!,
        tags: ["Frontend"],
      ),

      Todo(
        id: "4", groupId: nil, owner: "u1", content: "Holiday", status: .todo, detail: "",
        date: calendar.date(byAdding: .day, value: 2, to: today)!, tags: ["Urgent"],
      ), // Pink

      Todo(
        id: "5", groupId: nil, owner: "u1", content: "Reserve Army 11AM", status: .todo,
        detail: "", date: calendar.date(byAdding: .day, value: 20, to: today)!,
        tags: ["Default"],
      ), // Indigo
    ]
  }
}

// MARK: - Calendar Cell

struct CalendarCell: View {
  let date: Date
  let currentMonth: Date
  let tasks: [Todo]
  let cellHeight: CGFloat
  @Binding var selectedTask: Todo?
  let onDrop: (Todo) -> Void

  private let calendar = Calendar.current

  // Layout constants
  private let dateHeaderHeight: CGFloat = 28
  private let itemHeight: CGFloat = 22
  private let itemSpacing: CGFloat = 2
  private let moreButtonHeight: CGFloat = 18

  private var isCurrentMonth: Bool {
    calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
  }

  private var isToday: Bool {
    calendar.isDateInToday(date)
  }

  /// Calculate max visible items based on available cell height
  private var maxVisibleItems: Int {
    let availableHeight = cellHeight - dateHeaderHeight - moreButtonHeight - 8
    let itemTotalHeight = itemHeight + itemSpacing
    return max(1, Int(availableHeight / itemTotalHeight))
  }

  private var visibleTasks: [Todo] {
    Array(tasks.prefix(maxVisibleItems))
  }

  private var hiddenTaskCount: Int {
    max(0, tasks.count - maxVisibleItems)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      // Date Number
      Text("\(calendar.component(.day, from: date))")
        .font(.system(size: 14, weight: isToday ? .bold : .medium))
        .foregroundStyle(isToday ? .primary : (isCurrentMonth ? .primary : .secondary))
        .opacity(isCurrentMonth ? 1 : 0.4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(6)

      // Tasks (limited by available space)
      VStack(alignment: .leading, spacing: itemSpacing) {
        ForEach(visibleTasks) { task in
          TaskCard(task: task, style: .compact)
            .draggable(task)
            .onTapGesture {
              selectedTask = task
            }
            .opacity(selectedTask?.id == task.id ? 1.0 : (selectedTask == nil ? 1.0 : 0.6))
        }

        // "More" indicator when items are hidden
        if hiddenTaskCount > 0 {
          Text("+\(hiddenTaskCount) more")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
      }
      .padding(.horizontal, 2)

      Spacer()
    }
    .background(
      Rectangle() // Borders
        .stroke(Color.secondary.opacity(0.1), lineWidth: 0.5),
    )
    .background(isToday ? Color.blue.opacity(0.05) : Color.clear)
    .dropDestination(for: Todo.self) { droppedTasks, _ in
      if let task = droppedTasks.first {
        onDrop(task)
        return true
      }
      return false
    }
  }
}
