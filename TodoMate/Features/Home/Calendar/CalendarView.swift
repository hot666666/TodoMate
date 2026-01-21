//
//  CalendarView.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SimpleOverlaySystem
import SwiftUI
import TodoMateDomain

// MARK: - CalendarView

struct CalendarView: View {
  // MARK: - Environment

  @Environment(\.overlayManager) private var overlay

  // MARK: - State

  @State private var viewModel: TodoCalendarViewModel

  // MARK: - Init

  init(container: CoreDIContainer) {
    _viewModel = State(initialValue: TodoCalendarViewModel(container: container))
  }

  // MARK: - Body

  var body: some View {
    VStack(spacing: 0) {
      calendarHeader
      weekdayHeader
      calendarGrid
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(nsColor: .windowBackgroundColor))
    .accessibilityIdentifier("personalCalendarView")
    .environment(viewModel)
    .toolbar { HomeToolbarContent() }
    .onAppear {
      viewModel.overlay = overlay
    }
    .task(id: viewModel.currentDate) {
      await viewModel.startObserving()
    }
  }

  private var calendarHeader: some View {
    PageHeader(title: viewModel.headerTitle) {
      HStack(spacing: 6) {
        Button {
          viewModel.previousMonth()
        } label: {
          Image(systemName: "chevron.left")
            .font(.caption.bold())
            .frame(width: 28, height: 28)
            .contentShape(.rect)
        }
        .background(.ultraThinMaterial)
        .clipShape(.circle)

        Button {
          viewModel.goToday()
        } label: {
          Text("Today")
            .padding(.horizontal, 12)
            .frame(height: 28)
            .font(.caption.bold())
            .contentShape(.rect)
        }
        .background(.ultraThinMaterial)
        .clipShape(.capsule)

        Button {
          viewModel.nextMonth()
        } label: {
          Image(systemName: "chevron.right")
            .font(.caption.bold())
            .frame(width: 28, height: 28)
            .contentShape(.rect)
        }
        .background(.ultraThinMaterial)
        .clipShape(.circle)
      }
      .buttonStyle(.plain)
    }
  }

  private var weekdayHeader: some View {
    LazyVGrid(columns: TodoCalendarViewModel.columns, spacing: 0) {
      ForEach(viewModel.weekdays, id: \.self) { day in
        Text(day)
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
      }
    }
  }

  private var calendarGrid: some View {
    GeometryReader { geometry in
      let cellHeight = geometry.size.height / CGFloat(DesignSystem.Layout.calendarRowCount)

      LazyVGrid(columns: TodoCalendarViewModel.columns, spacing: 0) {
        ForEach(viewModel.days, id: \.self) { date in
          let todos = viewModel.todos(for: date)
          let isToday = viewModel.isToday(date)
          let isCurrentMonth = viewModel.isCurrentMonth(date)

          CalendarCell(
            date: date,
            cellHeight: cellHeight,
            todos: todos,
            isToday: isToday,
            isCurrentMonth: isCurrentMonth,
          )
          .onTapGesture {
            viewModel.presentDayTodoList(for: date)
          }
          .dropDestination(for: Todo.self) { items, _ in
            viewModel.handleDrop(todos: items, to: date)
          }
          .frame(height: cellHeight)
        }
      }
    }
  }
}

#Preview {
  CalendarView(container: CoreDIContainer.preview)
    .environment(CoreDIContainer.preview)
}
