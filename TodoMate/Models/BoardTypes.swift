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
  case last3Days = "최근 3일"
  case lastWeek = "최근 1주"

  var dateRange: ClosedRange<Date> {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)
    // Future is effectively infinite for "active" tasks, but typically we want to show all future tasks?
    // Board logic: "Today" usually means "Due Today" or "Created Today"?
    // The original logic was `start...endOfToday` (basically just today).
    // Board typically shows "ToDo", "InProgress", "Done".
    // "Today" likely means: Show tasks relevant to Today.
    // If I select "Last 3 Days", it probably means inclusion of tasks from 3 days ago + Today + Future?
    // The original `lastWeek` was `weekAgo...endOfToday`.
    // It seems it filters by DATE property.
    // If I have a task due tomorrow, does "Today" filter show it?
    // Original predicate: `todo.date >= start && todo.date <= end`
    // So "Today" only showed tasks for today.
    // "Last Week" showed tasks from last week up to today.
    // It seems Future tasks were excluded?
    // If `endOfToday` is "tomorrow 00:00", then future tasks are excluded.
    // That seems odd for a Kanban board unless it's a "Daily Log".
    // I will stick to the original logic's range ending at `endOfToday`.

    let endOfToday = calendar.date(byAdding: .day, value: 1, to: today)!

    switch self {
    case .today:
      return today ... endOfToday
    case .last3Days:
      let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
      return threeDaysAgo ... endOfToday
    case .lastWeek:
      let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
      return weekAgo ... endOfToday
    }
  }
}

// MARK: - Scroll Position

enum BoardScrollPosition: String, Hashable {
  case leading
  case trailing
}
