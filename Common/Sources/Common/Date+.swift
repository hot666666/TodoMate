//
//  Date+.swift
//  TodoMateInfra
//
//  Created by agent on 1/14/26.
//

import Foundation

public extension Date {
  /// Format: `yyyy/MM/dd`
  var yearMonthDay: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd"
    return formatter.string(from: self)
  }

  /// Format: `yyyy M월`
  var yearMonth: String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy M월"
    return dateFormatter.string(from: self)
  }

  func isSameDay(as date: Date) -> Bool {
    Calendar.current.isDate(self, inSameDayAs: date)
  }

  func isSameMonth(as date: Date) -> Bool {
    Calendar.current.isDate(self, equalTo: date, toGranularity: .month)
  }

  var isToday: Bool {
    Calendar.current.isDateInToday(self)
  }

  var startOfDay: Date {
    Calendar.current.startOfDay(for: self)
  }

  var endOfDay: Date {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: self)
    let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
    return calendar.date(byAdding: .second, value: -1, to: nextDay)!
  }

  var dayRange: ClosedRange<Date> {
    startOfDay ... endOfDay
  }

  var monthRange: ClosedRange<Date> {
    startDayOfMonth ... endDayOfMonth
  }

  /// 해당 월의 첫 번째 날 (1일 00:00:00)
  var startDayOfMonth: Date {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month], from: self)
    return calendar.date(from: components) ?? self
  }

  /// 해당 월의 마지막 날 (다음 달 1일의 하루 전)
  var endDayOfMonth: Date {
    let calendar = Calendar.current
    let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: self))!
    let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
    let endOfMonth = calendar.date(byAdding: .day, value: -1, to: startOfNextMonth)!
    return endOfMonth
  }

  /// 오늘이면 시간(HH:mm:ss), 아니면 날짜(yy/MM/dd)
  var timeOrDateString: String {
    let calendar = Calendar.current
    let formatter = DateFormatter()
    if calendar.isDateInToday(self) {
      formatter.dateFormat = "HH:mm:ss"
    } else {
      formatter.dateFormat = "yy/MM/dd"
    }
    return formatter.string(from: self)
  }

  /// 날짜를 헤더용 문자열로 변환
  /// - 오늘: "오늘"
  /// - 어제: "어제"
  /// - 그 외: "M월 d일"
  var headerFormatted: String {
    let calendar = Calendar.current
    let startOfDate = calendar.startOfDay(for: self)
    let startOfNow = calendar.startOfDay(for: .now)

    if startOfDate == startOfNow {
      return "오늘"
    } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfNow),
              startOfDate == calendar.startOfDay(for: yesterday) {
      return "어제"
    } else {
      return formatted(.dateTime.month().day())
    }
  }
}
