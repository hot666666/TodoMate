//
//  CalendarDayServiceImpl.swift
//  Todo
//
//  Created by hs on 6/28/25.
//

import Foundation
import TodoMateDomain

public final class CalendarDayServiceImpl: CalendarDayService {
  private let calendar: Calendar

  public init(calendar: Calendar = .current) {
    self.calendar = calendar
  }

  public func moveMonth(of date: Date, by value: Int) -> Date {
    calendar.date(byAdding: .month, value: value, to: date)!
  }

  public func countDays(in range: ClosedRange<Date>) -> Int {
    calendar.dateComponents([.day], from: range.lowerBound, to: range.upperBound).day! + 1
  }

  public func getCalendarDays(in month: Date) -> [CalendarDay] {
    let range = getRange(for: month)
    let currentMonth = calendar.component(.month, from: month)

    return toSequence(from: range)
      .map { date in
        CalendarDay(
          day: calendar.component(.day, from: date),
          isCurrentMonth: calendar.component(.month, from: date) == currentMonth,
          date: date,
        )
      }
  }

  public func getRange(for month: Date) -> ClosedRange<Date> {
    let firstDayOfMonth = calendar.date(
      from: calendar.dateComponents([.year, .month], from: month))!
    let lastDayOfMonth = calendar.date(
      byAdding: DateComponents(month: 1, day: -1), to: firstDayOfMonth,
    )!

    let firstWeekday = calendar.firstWeekday
    let weekdayOfFirstDay = calendar.component(.weekday, from: firstDayOfMonth)
    let daysToSubtract = (7 + weekdayOfFirstDay - firstWeekday) % 7
    let startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstDayOfMonth)!

    let weekdayOfLastDay = calendar.component(.weekday, from: lastDayOfMonth)
    let daysToAdd = (7 - ((weekdayOfLastDay - firstWeekday + 7) % 7) - 1) % 7
    let endDate = calendar.date(byAdding: .day, value: daysToAdd, to: lastDayOfMonth)!

    return startDate ... endDate
  }

  private func toSequence(from range: ClosedRange<Date>) -> [Date] {
    sequence(first: range.lowerBound) {
      self.calendar.date(byAdding: .day, value: 1, to: $0)
    }
    .prefix(while: { $0 <= range.upperBound })
  }
}
