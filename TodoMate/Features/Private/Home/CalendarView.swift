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
  // MARK: - Properties

  @Environment(\.overlayManager) private var overlay
  @Environment(CoreDIContainer.self) private var coreDI

  let viewModel: TodoCalendarViewModel

  // MARK: - Body

  var body: some View {
    VStack(spacing: 0) {
      calendarHeader
      weekdayHeader

      // Calendar Content
      GeometryReader { geometry in
        let cellHeight = geometry.size.height / CGFloat(DesignSystem.Layout.calendarRowCount)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        LazyVGrid(columns: columns, spacing: 0) {
          ForEach(viewModel.days, id: \.self) { date in
            let cellTodos = viewModel.todos(for: date)
            let isCurrentMonth = viewModel.isCurrentMonth(date)
            let isToday = viewModel.isToday(date)
            let dayString = "\(coreDI.calendar.component(.day, from: date))"

            CalendarCell(
              date: date,
              dayString: dayString,
              isCurrentMonth: isCurrentMonth,
              isToday: isToday,
              todos: cellTodos,
              cellHeight: cellHeight,
              selectedTodoId: viewModel.selectedTodoId,
              onDrop: { todo in
                viewModel.updateDate(of: todo, to: date)
              },
              onTapTodo: { todo in
                presentTodoSheet(for: todo)
              },
              onTapDate: { date in
                presentDayTodoList(for: date)
              },
              onTapMore: { date in
                presentDayTodoList(for: date)
              },
              onStatusChange: { todo in
                viewModel.update(todo)
              },
              onDuplicate: { todo in
                viewModel.duplicate(todo)
              },
              onDelete: { todo in
                viewModel.delete(todo)
              },
            )
            .frame(height: cellHeight)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(nsColor: .windowBackgroundColor))
    .accessibilityIdentifier("personalCalendarView")
    .toolbar {
      HomeToolbarContent()
    }
    .task(id: viewModel.currentDate) {
      viewModel.selectedTodoId = nil
      await viewModel.startObserving()
    }
  }

  // MARK: - Subviews

  private var calendarHeader: some View {
    HStack(alignment: .top) {
      Text(viewModel.headerTitle)
        .font(.title)

      Spacer()

      HStack(spacing: 8) {
        Button {
          viewModel.previousMonth()
        } label: {
          Image(systemName: "chevron.left")
        }

        Button("Today") {
          viewModel.goToday()
        }

        Button {
          viewModel.nextMonth()
        } label: {
          Image(systemName: "chevron.right")
        }
      }
      .buttonStyle(.bordered)
    }
    .padding(.horizontal)
  }

  private var weekdayHeader: some View {
    let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    return LazyVGrid(columns: columns, spacing: 0) {
      ForEach(viewModel.weekdays, id: \.self) { day in
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
        viewModel: viewModel,
        onTapTodo: { todo in
          presentTodoSheet(for: todo)
        },
      )
    }
  }
}

// MARK: - Calendar Cell

private struct CalendarCell: View {
  let date: Date
  let dayString: String
  let isCurrentMonth: Bool
  let isToday: Bool
  let todos: [Todo]
  let cellHeight: CGFloat
  let selectedTodoId: String?

  let onDrop: (Todo) -> Void
  let onTapTodo: (Todo) -> Void
  let onTapDate: (Date) -> Void
  let onTapMore: (Date) -> Void
  let onStatusChange: (Todo) -> Void
  let onDuplicate: (Todo) -> Void
  let onDelete: (Todo) -> Void

  private var maxVisibleItems: Int {
    let availableHeight = cellHeight - DesignSystem.Layout.calendarCellHeaderHeight
    let itemHeight = DesignSystem.Layout.calendarCellItemHeight
    return max(0, Int(availableHeight / itemHeight))
  }

  private var showMore: Bool {
    todos.count > maxVisibleItems
  }

  private var visibleCount: Int {
    showMore ? max(0, maxVisibleItems - 1) : todos.count
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      dateHeader
      tasksList
      Spacer(minLength: 0)
    }
    .background(
      Rectangle()
        .stroke(Color.secondary.opacity(0.1), lineWidth: 0.5),
    )
    .background(isToday ? Color.blue.opacity(0.05) : Color.clear)
    .dropDestination(for: Todo.self) { droppedTodos, _ in
      if let todo = droppedTodos.first {
        onDrop(todo)
        return true
      }
      return false
    }
  }

  private var dateHeader: some View {
    Button {
      onTapDate(date)
    } label: {
      Text(dayString)
        .font(.system(size: 14, weight: isToday ? .bold : .medium))
        .foregroundStyle(isToday ? .primary : (isCurrentMonth ? .primary : .secondary))
        .opacity(isCurrentMonth ? 1 : 0.4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(6)
        .contentShape(.rect)
    }
    .buttonStyle(.plain)
  }

  private var tasksList: some View {
    VStack(alignment: .leading, spacing: 2) {
      ForEach(todos.prefix(visibleCount)) { todo in
        TodoCard(
          style: .compact,
          todo: todo,
          onStatusChange: { newStatus in
            var updated = todo
            updated.status = newStatus
            onStatusChange(updated)
          },
          onDuplicate: { onDuplicate(todo) },
          onDelete: { onDelete(todo) },
        )
        .draggable(todo)
        .onTapGesture {
          onTapTodo(todo)
        }
        .opacity(opacity(for: todo))
      }

      if showMore {
        Button {
          onTapMore(date)
        } label: {
          Text("+\(todos.count - visibleCount) more")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 2)
  }

  private func opacity(for todo: Todo) -> Double {
    if let selected = selectedTodoId {
      return selected == todo.id ? 1.0 : 0.6
    }
    return 1.0
  }
}

#Preview {
  CalendarView(viewModel: TodoCalendarViewModel.preview)
    .environment(CoreDIContainer.preview)
}
