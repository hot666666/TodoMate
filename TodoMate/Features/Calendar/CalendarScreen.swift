//
//  CalendarScreen.swift
//  Todo
//
//  Created by hs on 6/25/25.
//

import SwiftUI

struct CalendarScreen: View {
  @Environment(SessionStore.self) private var sessionStore
  @Environment(OverlayManager.self) private var overlayManager

  @State private var calculatedCellHeight: CGFloat = 90
  @State var calendarVM: CalendarScreenVM

  private var sheetPresenter: TodoSheetPresenter {
    TodoSheetPresenter(overlayManager: overlayManager)
  }

  private func addTodo(_ date: Date) {
    let newTodo = Todo(owner: sessionStore.userId, in: date)
    calendarVM.addTodo(newTodo, for: sessionStore.userId)
  }

  private func moveTodo(todoId: String, sourceDate: Date, targetDate: Date) {
    calendarVM.moveTodo(todoId: todoId, from: sourceDate, to: targetDate, for: sessionStore.userId)
  }

  private func copyTodo(_ todo: Todo) {
    calendarVM.copyTodo(todo, for: sessionStore.userId)
  }

  private func deleteTodo(_ todo: Todo) {
    overlayManager.presentConfirmation(
      title: "\(todo.content) 삭제",
      message: "이 할일을 삭제하시겠습니까?",
      destructiveActionTitle: "삭제"
    ) {
      calendarVM.deleteTodo(todo, for: sessionStore.userId)
    }
  }

  private func presentTodoEditSheet(for todo: Todo) {
    sheetPresenter.presentEditSheet(for: todo) {
      Task {
        await calendarVM.refresh(userId: sessionStore.userId)
      }
    }
  }

  private func presentAddTodoSheet() {
    sheetPresenter.presentAddSheet(for: sessionStore.userId)
  }

  private func updateCellHeight(containerHeight: CGFloat) {
    let weekCount = CGFloat(calendarVM.calendarDays.count / 7)
    let gridSpacing = CalendarDesignSystem.Layout.gridSpacing * (weekCount - 1)
    let availableHeight = containerHeight - CalendarDesignSystem.Component.Screen.fixedHeight - gridSpacing
    let calculatedHeight = availableHeight / weekCount

    calculatedCellHeight = max(CalendarDesignSystem.Component.Screen.minCellHeight, calculatedHeight)
  }
}

extension CalendarScreen {
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        backgroundGradient

        VStack {
          headerSection
            .padding(.vertical)
          weekdaySection
          calendarGridSection
            .environment(\.calendarCellHeight, calculatedCellHeight)
        }
        .padding(.horizontal, CalendarDesignSystem.Layout.horizontalPadding)
        .padding(.top, 20)
        .frame(maxHeight: .infinity, alignment: .top)

        closeButtonOverlay
      }
      .loadingOverlay(isLoading: calendarVM.isLoading)
      .onAppear {
        updateCellHeight(containerHeight: geometry.size.height)
      }
      .onChange(of: geometry.size.height) { _, newHeight in
        updateCellHeight(containerHeight: newHeight)
      }
    }
    .task {
      await calendarVM.load(userId: sessionStore.userId)
    }
    .onKeyPress([
      (.escape, overlayManager.pop),
      (.newTodo, presentAddTodoSheet),
    ])
  }

  private var backgroundGradient: some View {
    Color.customDarkBg
      .ignoresSafeArea()
  }

  private var headerSection: some View {
    CalendarHeader(
      yearMonth: calendarVM.currentDate.yearMonth,
      onPrevious: { calendarVM.moveToPrevMonth(userId: sessionStore.userId) },
      onNext: { calendarVM.moveToNextMonth(userId: sessionStore.userId) },
      onToday: { calendarVM.moveToCurrMonth(userId: sessionStore.userId) }
    )
    .padding(.horizontal, 8)
  }

  private var weekdaySection: some View {
    CalendarWeekday()
      .padding(.horizontal, CalendarDesignSystem.Layout.gridContainerPadding)
  }

  private var closeButtonOverlay: some View {
    Button(action: { overlayManager.pop() }) {
      Image(systemName: "xmark.circle.fill")
        .font(.title2)
        .foregroundStyle(.secondary, .ultraThinMaterial)
        .symbolRenderingMode(.hierarchical)
    }
    .buttonStyle(.plain)
    .padding(10)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
  }

  private var calendarGridSection: some View {
    LazyVGrid(columns: CalendarDesignSystem.Layout.columns, spacing: CalendarDesignSystem.Layout.gridSpacing) {
      ForEach(Array(calendarVM.calendarDays.enumerated()), id: \.offset) { index, calendarDay in
        CalendarDayCell(
          calendarDay: calendarDay,
          todos: calendarVM.todosInMonth[calendarDay.date.startOfDay] ?? [],
          cornerPosition: CornerPosition.position(for: index, totalDays: calendarVM.calendarDays.count),
          onAddTodo: addTodo,
          onMoveTodo: moveTodo,
          onCopyTodo: copyTodo,
          onDeleteTodo: deleteTodo,
          onTapTodo: presentTodoEditSheet
        )
      }
    }
    .padding(CalendarDesignSystem.Layout.gridContainerPadding)
    .background(
      RoundedRectangle(cornerRadius: CalendarDesignSystem.Layout.gridCornerRadius)
        .fill(Color.white.opacity(0.05))
    )
    .padding(.bottom, CalendarDesignSystem.Layout.gridContainerBottomPadding)
  }
}

#Preview {
  CalendarScreen(calendarVM: .init(container: DIContainer.preview))
    .environment(SessionStore.preview)
    .frame(width: 500, height: 800)
}
