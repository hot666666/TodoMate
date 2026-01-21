//
//  TodoDatePicker.swift
//  Todo
//
//  Created by hs on 6/29/25.
//

import SwiftUI
import TodoMateData
import TodoMateDomain

struct TodoDatePicker: View {
  @Environment(CoreDIContainer.self) private var coreDI

  // MARK: - Properties

  @Binding var date: Date
  private let onDismiss: () -> Void

  // MARK: - State

  @State private var displayMonth: Date

  // MARK: - Init

  init(
    date: Binding<Date>,
    onDismiss: @escaping () -> Void,
  ) {
    _date = date
    self.onDismiss = onDismiss

    // 월의 첫날로 정규화하여 일관된 월 이동 보장
    let calendar = Calendar.current
    let normalizedMonth =
      calendar.date(
        from: calendar.dateComponents([.year, .month], from: date.wrappedValue),
      ) ?? date.wrappedValue

    _displayMonth = State(initialValue: normalizedMonth)
  }

  // MARK: - Body

  var body: some View {
    VStack(spacing: 0) {
      header
        .padding(.bottom, DesignSystem.TodoSheet.Spacing.small)

      CalendarWeekday()

      daysGrid
        .padding(.top, 5)
    }
    .frame(maxHeight: .infinity, alignment: .top)
    .padding(DesignSystem.TodoSheet.DatePicker.padding)
    .frame(
      width: DesignSystem.TodoSheet.DatePicker.width,
      height: DesignSystem.TodoSheet.DatePicker.height,
    )
    .materialCardOverlay()
    .onKeyPress(.escape) {
      onDismiss()
      return .handled
    }
  }

  // MARK: - Subviews

  private var header: some View {
    HStack {
      Text(displayMonth.yearMonth)
        .font(.subheadline)
        .fontWeight(.semibold)

      Spacer()

      monthNavigationButton(direction: -1, icon: "chevron.left")
      monthNavigationButton(direction: 1, icon: "chevron.right")
    }
  }

  private func monthNavigationButton(direction: Int, icon: String) -> some View {
    Button {
      displayMonth = coreDI.calendarDayService.moveMonth(of: displayMonth, by: direction)
    } label: {
      Image(systemName: icon)
        .foregroundColor(.secondary)
        .contentShape(.rect)
    }
    .buttonStyle(.plain)
  }

  private var daysGrid: some View {
    let calendarDays = coreDI.calendarDayService.getCalendarDays(in: displayMonth)

    return LazyVGrid(
      columns: Array(repeating: GridItem(.flexible()), count: 7),
      spacing: DesignSystem.TodoSheet.Spacing.small,
    ) {
      ForEach(calendarDays) { calendarDay in
        DayCell(
          calendarDay: calendarDay,
          isSelected: calendarDay.date.isSameDay(as: date),
        )
        .onTapGesture {
          selectDate(calendarDay.date)
        }
      }
    }
  }

  // MARK: - Actions

  private func selectDate(_ newDate: Date) {
    date = newDate
    if !newDate.isSameMonth(as: displayMonth) {
      displayMonth = newDate
    }
    onDismiss()
  }
}

// MARK: - DayCell

private struct DayCell: View {
  let calendarDay: CalendarDay
  let isSelected: Bool

  private var isToday: Bool {
    calendarDay.date.isToday
  }

  var body: some View {
    Text("\(calendarDay.day)")
      .font(.caption)
      .fontWeight(isSelected ? .semibold : .medium)
      .foregroundColor(foregroundColor)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .aspectRatio(1, contentMode: .fit)
      .background(background)
      .contentShape(.rect)
  }

  @ViewBuilder
  private var background: some View {
    if isSelected {
      Circle()
        .fill(Color.accentColor)
    }
  }

  private var foregroundColor: Color {
    if isSelected {
      return .white
    }
    if !calendarDay.isCurrentMonth {
      return .secondary.opacity(0.6)
    }
    if isToday {
      return .accentColor
    }
    return .primary
  }
}

#Preview {
  @State @Previewable var date = Date()

  VStack(spacing: 20) {
    TodoDatePicker(date: $date, onDismiss: {})
      .background(Color(nsColor: .windowBackgroundColor))
      .cornerRadius(12)
      .shadow(radius: 10)
  }
  .padding()
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(Color(nsColor: .underPageBackgroundColor))
}
