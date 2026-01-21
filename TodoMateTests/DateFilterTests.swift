//
//  DateFilterTests.swift
//  TodoMateTests
//
//  Testing date filter logic for BoardView
//
//  Created by agent on 1/8/26.
//
//

import Foundation
import Testing

@testable import TodoMate

@Suite("DateFilter Tests")
struct DateFilterTests {
  // MARK: - Date Range Tests

  @Test("Today filter contains only today's date")
  func todayFilterOnlyContainsToday() {
    // Given
    let filter = DateFilter.today
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)

    // When
    let range = filter.dateRange

    // Then
    #expect(range.contains(today))
    #expect(range.contains(.now))

    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
    #expect(!range.contains(yesterday))
  }

  @Test("Last3Days filter contains past 3 days and today")
  func last3DaysFilterContainsPast3Days() {
    // Given
    let filter = DateFilter.last3Days
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)

    // When
    let range = filter.dateRange

    // Then
    // Today should be included
    #expect(range.contains(today))

    // 3 days ago should be included
    let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
    #expect(range.contains(threeDaysAgo))

    // 4 days ago should NOT be included
    let fourDaysAgo = calendar.date(byAdding: .day, value: -4, to: today)!
    #expect(!range.contains(fourDaysAgo))
  }

  @Test("LastWeek filter contains past 7 days")
  func lastWeekFilterContainsPast7Days() {
    // Given
    let filter = DateFilter.lastWeek
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)

    // When
    let range = filter.dateRange

    // Then
    // Today should be included
    #expect(range.contains(today))
    #expect(range.contains(.now))

    // 3 days ago should be included
    let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
    #expect(range.contains(threeDaysAgo))

    // 7 days ago should be included
    let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today)!
    #expect(range.contains(sevenDaysAgo))

    // 8 days ago should NOT be included
    let eightDaysAgo = calendar.date(byAdding: .day, value: -8, to: today)!
    #expect(!range.contains(eightDaysAgo))
  }

  // MARK: - Filter Raw Value Tests

  @Test("Filter raw values are Korean")
  func filterRawValuesAreKorean() {
    #expect(DateFilter.today.rawValue == "오늘")
    #expect(DateFilter.last3Days.rawValue == "최근 3일")
    #expect(DateFilter.lastWeek.rawValue == "최근 1주")
  }

  // MARK: - CaseIterable Tests

  @Test("Filter has 3 cases")
  func filterHasThreeCases() {
    #expect(DateFilter.allCases.count == 3)
  }
}
