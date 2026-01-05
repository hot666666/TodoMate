//
//  CalendarDay.swift
//  TodoMate
//
//  Created by hs on 1/5/26.
//

import Foundation

struct CalendarDay: Identifiable {
  let id = UUID()
  let day: Int
  let isCurrentMonth: Bool
  let date: Date

  init(day: Int, isCurrentMonth: Bool, date: Date) {
    self.day = day
    self.isCurrentMonth = isCurrentMonth
    self.date = date
  }
}
