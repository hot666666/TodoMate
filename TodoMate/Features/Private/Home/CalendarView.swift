//
//  CalendarView.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//
//

import SimpleOverlaySystem
import SwiftData
import SwiftUI
import TodoMateDomain

// MARK: - CalendarView (Container)

struct CalendarView: View {
  @Environment(\.overlayManager) private var overlay
  @Environment(LocalTodoHelper.self) private var todoStore
  @State private var currentDate = Date()
  @State private var selectedTask: ViewTodo?

  private let calendar = Calendar.current

  var body: some View {
    VStack(spacing: 0) {
      calendarHeader
      weekdayHeader

      // Wrapper handles data fetching and grid rendering
      CalendarQueryWrapper(
        currentDate: currentDate,
        selectedTask: $selectedTask,
        onPresentSheet: { todo in
          presentTodoSheet(for: todo)
        },
        onPresentDayList: { date in
          presentDayTodoList(for: date)
        },
      )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(nsColor: .windowBackgroundColor))
    .accessibilityIdentifier("personalCalendarView")
    .toolbar {
      HomeToolbarContent()
    }
  }

  // MARK: - Components

  private var calendarHeader: some View {
    HStack(alignment: .top) {
      Text(currentDate.formatted(.dateTime.month(.wide).year()))
        .font(.title)

      Spacer()

      HStack(spacing: 8) {
        Button {
          currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
        } label: {
          Image(systemName: "chevron.left")
        }

        Button("Today") {
          currentDate = Date()
        }

        Button {
          currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
        } label: {
          Image(systemName: "chevron.right")
        }
      }
      .buttonStyle(.bordered)
    }
    .padding(.horizontal)
  }

  private var weekdayHeader: some View {
    let daysOfWeek = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    return LazyVGrid(columns: columns, spacing: 0) {
      ForEach(daysOfWeek, id: \.self) { day in
        Text(day)
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
      }
    }
    .overlay(Divider(), alignment: .bottom)
  }

  // MARK: - Navigation

  private func presentTodoSheet(for originalTodo: Todo) {
    let editableTodo = EditableTodo(from: originalTodo)
    overlay?.presentCentered(
      id: .todoSheet,
      backdropOpacity: 0,
      offset: CGPoint(x: 0, y: -120),
    ) {
      TodoSheet(editableTodo: editableTodo)
    }
  }

  private func presentDayTodoList(for date: Date) {
    overlay?.presentCentered(
      backdropOpacity: 0,
    ) {
      DayTodoList(
        date: date,
        onTapTodo: { todo in
          presentTodoSheet(for: todo)
        },
      )
    }
  }
}

// MARK: - CalendarQueryWrapper

private struct CalendarQueryWrapper: View {
  @Environment(LocalTodoHelper.self) private var todoStore
  @Query private var sdTodos: [SDTodo]

  let currentDate: Date
  @Binding var selectedTask: ViewTodo?
  let onPresentSheet: (Todo) -> Void
  let onPresentDayList: (Date) -> Void

  // Calculated days for grid
  private let days: [Date]

  init(
    currentDate: Date,
    selectedTask: Binding<ViewTodo?>,
    onPresentSheet: @escaping (Todo) -> Void,
    onPresentDayList: @escaping (Date) -> Void,
  ) {
    self.currentDate = currentDate
    _selectedTask = selectedTask
    self.onPresentSheet = onPresentSheet
    self.onPresentDayList = onPresentDayList

    // Calculate Days
    let calendar = Calendar.current
    let monthInterval = calendar.dateInterval(of: .month, for: currentDate)!
    let monthStart = monthInterval.start
    let weekday = calendar.component(.weekday, from: monthStart)
    let startOffset = weekday - 1
    let startDisplayDate = calendar.date(byAdding: .day, value: -startOffset, to: monthStart)!

    // 42 days fixed
    days = (0 ..< 42).compactMap { offset in
      calendar.date(byAdding: .day, value: offset, to: startDisplayDate)
    }

    // Predicate: Start <= date <= End
    let start = days.first ?? .distantPast
    let end = days.last ?? .distantFuture
    let predicate = #Predicate<SDTodo> { todo in
      todo.date >= start && todo.date <= end && !todo.isDeleted
    }
    _sdTodos = Query(filter: predicate)
  }

  var body: some View {
    let viewTodos = sdTodos.map { ViewTodo(from: $0.toDomain()) }

    CalendarContent(
      days: days,
      currentDate: currentDate,
      todos: viewTodos,
      selectedTask: $selectedTask,
      onDrop: { viewTodo, date in
        moveTask(viewTodo, to: date)
      },
      onTapTask: { viewTodo in
        if let todo = findDomainTodo(for: viewTodo) {
          onPresentSheet(todo)
        }
      },
      onTapDate: { date, _ in
        onPresentDayList(date)
      },
      onTapMore: { date, _ in
        onPresentDayList(date)
      },
      onStatusChange: { viewTodo, status in
        updateTaskStatus(viewTodo, to: status)
      },
      onDuplicateTask: { viewTodo in
        duplicateTask(viewTodo)
      },
      onDeleteTask: { viewTodo in
        deleteTask(viewTodo)
      },
    )
  }

  // MARK: - Logic

  private func findDomainTodo(for viewTodo: ViewTodo) -> Todo? {
    sdTodos.first(where: { $0.id == viewTodo.id })?.toDomain()
  }

  private func moveTask(_ task: ViewTodo, to date: Date) {
    guard var todo = findDomainTodo(for: task) else { return }
    todo.date = Calendar.current.startOfDay(for: date)
    todo.updatedAt = Date()
    todoStore.updateTodo(todo)
  }

  private func updateTaskStatus(_ task: ViewTodo, to newStatus: ViewTodoStatus) {
    guard let todo = findDomainTodo(for: task) else { return }
    todoStore.updateStatus(todo, status: newStatus.toDomainStatus())
  }

  private func duplicateTask(_ task: ViewTodo) {
    guard let todo = findDomainTodo(for: task) else { return }
    var newTodo = Todo.copy(from: todo)
    newTodo.detail = ""
    todoStore.addTodo(newTodo)
  }

  private func deleteTask(_ task: ViewTodo) {
    guard let todo = findDomainTodo(for: task) else { return }
    todoStore.deleteTodo(todo)
  }
}

// MARK: - CalendarContent

private struct CalendarContent: View {
  let days: [Date]
  let currentDate: Date
  let todos: [ViewTodo]
  @Binding var selectedTask: ViewTodo?

  let onDrop: (ViewTodo, Date) -> Void
  let onTapTask: (ViewTodo) -> Void
  let onTapDate: (Date, [ViewTodo]) -> Void
  let onTapMore: (Date, [ViewTodo]) -> Void

  let onStatusChange: (ViewTodo, ViewTodoStatus) -> Void
  let onDuplicateTask: (ViewTodo) -> Void
  let onDeleteTask: (ViewTodo) -> Void

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
  private let calendar = Calendar.current

  var body: some View {
    GeometryReader { geometry in
      let cellHeight = geometry.size.height / CGFloat(DesignSystem.Layout.calendarRowCount)

      LazyVGrid(columns: columns, spacing: 0) {
        ForEach(days, id: \.self) { date in
          // Helper to filter todos for this cell
          let cellTodos = todos.filter { calendar.isDate($0.date, inSameDayAs: date) }

          CalendarCell(
            date: date,
            currentMonth: currentDate,
            tasks: cellTodos,
            cellHeight: cellHeight,
            selectedTask: $selectedTask,
            onDrop: { task in onDrop(task, date) },
            onTapTask: onTapTask,
            onTapDate: onTapDate,
            onTapMore: onTapMore,
            onStatusChange: onStatusChange,
            onDuplicateTask: onDuplicateTask,
            onDeleteTask: onDeleteTask,
          )
          .frame(height: cellHeight)
        }
      }
    }
  }
}

// MARK: - Calendar Cell

struct CalendarCell: View {
  let date: Date
  let currentMonth: Date
  let tasks: [ViewTodo]
  let cellHeight: CGFloat
  @Binding var selectedTask: ViewTodo?
  let onDrop: (ViewTodo) -> Void
  let onTapTask: (ViewTodo) -> Void
  let onTapDate: (Date, [ViewTodo]) -> Void
  let onTapMore: (Date, [ViewTodo]) -> Void

  let onStatusChange: (ViewTodo, ViewTodoStatus) -> Void
  let onDuplicateTask: (ViewTodo) -> Void
  let onDeleteTask: (ViewTodo) -> Void

  private let calendar = Calendar.current

  private var isCurrentMonth: Bool {
    calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
  }

  private var isToday: Bool {
    calendar.isDateInToday(date)
  }

  private var maxVisibleItems: Int {
    let availableHeight = cellHeight - DesignSystem.Layout.calendarCellHeaderHeight
    let itemHeight = DesignSystem.Layout.calendarCellItemHeight
    return max(0, Int(availableHeight / itemHeight))
  }

  private var showMore: Bool {
    tasks.count > maxVisibleItems
  }

  private var visibleCount: Int {
    showMore ? max(0, maxVisibleItems - 1) : tasks.count
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      // Date Number - tappable
      Button {
        onTapDate(date, tasks)
      } label: {
        Text("\(calendar.component(.day, from: date))")
          .font(.system(size: 14, weight: isToday ? .bold : .medium))
          .foregroundStyle(isToday ? .primary : (isCurrentMonth ? .primary : .secondary))
          .opacity(isCurrentMonth ? 1 : 0.4)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(6)
          .contentShape(.rect)
      }
      .buttonStyle(.plain)

      // Tasks
      VStack(alignment: .leading, spacing: 2) {
        ForEach(tasks.prefix(visibleCount)) { task in
          TaskCard(
            task: task,
            style: .compact,
            onStatusChange: { status in onStatusChange(task, status) },
            onDuplicate: { onDuplicateTask(task) },
            onDelete: { onDeleteTask(task) },
          )
          .draggable(task)
          .onTapGesture {
            onTapTask(task)
          }
          .opacity(
            selectedTask?.id == task.id
              ? 1.0 : (selectedTask == nil ? 1.0 : 0.6),
          )
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
  CalendarView()
    .environment(NavigationManager.preview)
    .environment(LocalTodoHelper.preview)
}
