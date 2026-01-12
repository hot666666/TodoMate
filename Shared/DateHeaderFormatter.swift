//
//  DateHeaderFormatter.swift
//  TodoMate
//
//  Created by agent on 1/9/26.
//

import Foundation

/// 메시지 날짜 헤더 포맷팅 유틸리티
enum DateHeaderFormatter {
  /// 날짜를 헤더용 문자열로 변환
  /// - 오늘: "오늘"
  /// - 어제: "어제"
  /// - 그 외: "M월 d일"
  static func format(_ date: Date, relativeTo referenceDate: Date = .now) -> String {
    let calendar = Calendar.current
    let startOfDate = calendar.startOfDay(for: date)
    let startOfReference = calendar.startOfDay(for: referenceDate)

    if startOfDate == startOfReference {
      return "오늘"
    } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfReference),
              startOfDate == calendar.startOfDay(for: yesterday) {
      return "어제"
    } else {
      return date.formatted(.dateTime.month().day())
    }
  }
}
