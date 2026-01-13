//
//  CalendarDayServiceImpl.swift
//  Todo
//
//  Created by hs on 6/28/25.
//

import Foundation

final class CalendarDayServiceImpl: CalendarDayService {
  private let calendar: Calendar

  init(calendar: Calendar = .current) {
    self.calendar = calendar
  }

  func moveMonth(of date: Date, by value: Int) -> Date {
    calendar.date(byAdding: .month, value: value, to: date)!
  }

  func countDays(in range: ClosedRange<Date>) -> Int {
    calendar.dateComponents([.day], from: range.lowerBound, to: range.upperBound).day! + 1
  }

  func getCalendarDays(in month: Date) -> [CalendarDay] {
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

  func getRange(for month: Date) -> ClosedRange<Date> {
    let firstDayOfMonth = calendar.date(
      from: calendar.dateComponents([.year, .month], from: month))!
    let lastDayOfMonth = calendar.date(
      byAdding: DateComponents(month: 1, day: -1), to: firstDayOfMonth,
    )!

    // 첫 주의 시작: 이번달 1일이 포함된 "주"의 시작일
    let firstWeekday = calendar.firstWeekday
    let weekdayOfFirstDay = calendar.component(.weekday, from: firstDayOfMonth)
    let daysToSubtract = (7 + weekdayOfFirstDay - firstWeekday) % 7
    let startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstDayOfMonth)!

    // 마지막 주의 끝: 이번달 마지막날이 포함된 "주"의 마지막 요일
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
