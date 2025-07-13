//
//  CalendarDay.swift
//  Todo
//
//  Created by hs on 7/4/25.
//

import Foundation

struct CalendarDay: Identifiable {
  let day: Int
  let isCurrentMonth: Bool
  let date: Date
  var id: Date { date }
}
