//
//  CalendarDay.swift
//  TodoMate
//
//  Created by hs on 1/5/26.
//

import Foundation

public struct CalendarDay: Identifiable {
  public let id = UUID()
  public let day: Int
  public let isCurrentMonth: Bool
  public let date: Date

  public init(day: Int, isCurrentMonth: Bool, date: Date) {
    self.day = day
    self.isCurrentMonth = isCurrentMonth
    self.date = date
  }
}
