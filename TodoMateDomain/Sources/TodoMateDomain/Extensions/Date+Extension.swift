import Foundation

public extension Date {
  func isSameMonth(as date: Date) -> Bool {
    Calendar.current.isDate(self, equalTo: date, toGranularity: .month)
  }

  func isSameDay(as date: Date) -> Bool {
    Calendar.current.isDate(self, inSameDayAs: date)
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

  // X월 1일 00:00:00으로 초기화
  var startDayOfMonth: Date {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month], from: self)
    return calendar.date(from: components) ?? self
  }

  var endDayOfMonth: Date {
    let calendar = Calendar.current
    let startOfMonth = calendar.date(
      from: calendar.dateComponents([.year, .month], from: self))!
    let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
    let endOfMonth = calendar.date(byAdding: .day, value: -1, to: startOfNextMonth)!
    return endOfMonth
  }

  var dayRange: ClosedRange<Date> {
    startOfDay ... endOfDay
  }

  var monthRange: ClosedRange<Date> {
    startDayOfMonth ... endDayOfMonth
  }
}
