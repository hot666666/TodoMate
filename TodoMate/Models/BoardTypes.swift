//
//  BoardTypes.swift
//  TodoMate
//
//  Created by agent on 1/11/26.
//

import Common
import Foundation

// MARK: - Date Filter

enum DateFilter: String, CaseIterable {
  case today = "오늘"
  case last3Days = "최근 3일"
  case lastWeek = "최근 1주"

  var dateRange: ClosedRange<Date> {
    let startOfToday = Date().startOfDay
    let endOfToday = startOfToday.endOfDay

    switch self {
    case .today:
      return startOfToday ... endOfToday
    case .last3Days:
      let threeDaysAgo = startOfToday.addingDays(-3)
      return threeDaysAgo ... endOfToday
    case .lastWeek:
      let weekAgo = startOfToday.addingDays(-7)
      return weekAgo ... endOfToday
    }
  }
}

// MARK: - Scroll Position

enum BoardScrollPosition: String, Hashable {
  case leading
  case trailing
}
