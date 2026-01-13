//
//  BoardTypes.swift
//  TodoMate
//
//  Created by agent on 1/11/26.
//

import Foundation

// MARK: - Date Filter

enum DateFilter: String, CaseIterable {
  case today = "오늘"
  case lastWeek = "최근 1주"
  case lastMonth = "최근 1달"

  var dateRange: ClosedRange<Date> {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)
    let endOfToday = calendar.date(byAdding: .day, value: 1, to: today)!

    switch self {
    case .today:
      return today ... endOfToday
    case .lastWeek:
      let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
      return weekAgo ... endOfToday
    case .lastMonth:
      let monthAgo = calendar.date(byAdding: .month, value: -1, to: today)!
      return monthAgo ... endOfToday
    }
  }
}

// MARK: - Scroll Position

enum BoardScrollPosition: String, Hashable {
  case leading
  case trailing
}
