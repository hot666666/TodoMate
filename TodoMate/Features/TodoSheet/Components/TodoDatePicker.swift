//
//  TodoDatePicker.swift
//  Todo
//
//  Created by hs on 6/29/25.
//

import SwiftUI

struct TodoDatePicker: View {
  @Binding var date: Date
  let calendarDayService: CalendarDayService

  init(date: Binding<Date>, calendarDayService: CalendarDayService = CalendarDayServiceImpl()) {
    _date = date
    self.calendarDayService = calendarDayService
  }

  var body: some View {
    PopoverView(date: $date, calendarDayService: calendarDayService)
      .padding(TodoSheetDesignSystem.Component.DatePicker.padding)
      .frame(width: TodoSheetDesignSystem.Component.DatePicker.width, height: TodoSheetDesignSystem.Component.DatePicker.height)
  }
}

// MARK: - PopoverView

private struct PopoverView: View {
  @Binding var date: Date
  @State private var displayMonth: Date
  let dateService: CalendarDayService

  init(date: Binding<Date>, calendarDayService: CalendarDayService) {
    _date = date
    dateService = calendarDayService
    // 월의 첫날로 정규화하여 일관된 월 이동 보장
    let calendar = Calendar.current
    let normalizedMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date.wrappedValue)) ?? date.wrappedValue
    _displayMonth = State(initialValue: normalizedMonth)
  }

  var body: some View {
    VStack(spacing: 0) {
      header
        .padding(.bottom, TodoSheetDesignSystem.Spacing.small)
      CalendarWeekday()
      daysGrid
        .padding(.top, 5)
    }
    .frame(maxHeight: .infinity, alignment: .top)
  }

  private var header: some View {
    HStack {
      Text(displayMonth.yearMonth)
        .font(.subheadline)
        .fontWeight(.semibold)

      Spacer()

      Button(action: {
        displayMonth = dateService.moveMonth(of: displayMonth, by: -1)
      }) {
        Image(systemName: "chevron.left")
          .foregroundColor(.secondary)
          .contentShape(.rect)
      }
      .buttonStyle(.plain)

      Button(action: {
        displayMonth = dateService.moveMonth(of: displayMonth, by: 1)
      }) {
        Image(systemName: "chevron.right")
          .foregroundColor(.secondary)
          .contentShape(.rect)
      }
      .buttonStyle(.plain)
    }
  }

  private var daysGrid: some View {
    let calendarDays = dateService.getCalendarDays(in: displayMonth)
    return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: TodoSheetDesignSystem.Spacing.small) {
      ForEach(calendarDays) { calendarDay in
        DayCell(
          calendarDay: calendarDay,
          isSelected: calendarDay.date.isSameDay(as: date)
        )
        .onTapGesture {
          date = calendarDay.date
          if !calendarDay.date.isSameMonth(as: displayMonth) {
            displayMonth = calendarDay.date
          }
        }
      }
    }
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
    TodoDatePicker(date: $date)
      .background(Color(nsColor: .windowBackgroundColor))
      .cornerRadius(12)
      .shadow(radius: 10)
  }
  .padding()
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(Color(nsColor: .underPageBackgroundColor))
}
