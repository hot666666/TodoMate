//
//  DateHeaderFormatterTests.swift
//  TodoMateTests
//
//  Created by agent on 1/9/26.
//

import Foundation
import Testing

@testable import TodoMate

@Suite("DateHeaderFormatter Tests")
struct DateHeaderFormatterTests {
  @Test("오늘 날짜는 '오늘'로 표시")
  func formatToday_returnsToday() {
    // Given
    let now = Date()

    // When
    let result = DateHeaderFormatter.format(now, relativeTo: now)

    // Then
    #expect(result == "오늘")
  }

  @Test("어제 날짜는 '어제'로 표시")
  func formatYesterday_returnsYesterday() {
    // Given
    let now = Date()
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!

    // When
    let result = DateHeaderFormatter.format(yesterday, relativeTo: now)

    // Then
    #expect(result == "어제")
  }

  @Test("2일 전 날짜는 날짜 형식으로 표시")
  func formatOlderDate_returnsMonthDay() {
    // Given
    let now = Date()
    let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: now)!

    // When
    let result = DateHeaderFormatter.format(twoDaysAgo, relativeTo: now)

    // Then
    // "오늘", "어제"가 아닌 다른 형식이어야 함
    #expect(result != "오늘")
    #expect(result != "어제")
    #expect(!result.isEmpty)
  }

  @Test("같은 날의 다른 시간대도 '오늘'로 표시")
  func formatSameDayDifferentTime_returnsToday() {
    // Given
    let calendar = Calendar.current
    let now = Date()
    let startOfDay = calendar.startOfDay(for: now)
    let endOfDay = calendar.date(byAdding: .hour, value: 23, to: startOfDay)!

    // When
    let result = DateHeaderFormatter.format(endOfDay, relativeTo: startOfDay)

    // Then
    #expect(result == "오늘")
  }
}
