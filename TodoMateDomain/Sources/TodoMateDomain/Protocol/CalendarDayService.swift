//
//  CalendarDayService.swift
//  TodoMate
//
//  Created by hs on 7/12/25.
//

import Foundation

public protocol CalendarDayService {
  func moveMonth(of date: Date, by value: Int) -> Date
  func countDays(in range: ClosedRange<Date>) -> Int
  func getRange(for month: Date) -> ClosedRange<Date>
  func getCalendarDays(in month: Date) -> [CalendarDay]
}
