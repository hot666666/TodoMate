//
//  CalendarManager.swift
//  TodoMate
//
//  Created by hs on 8/17/24.
//

import SwiftUI

class CalendarManager {
    static let shared = CalendarManager()
    
    private let calendar: Calendar
    
    private init(calendar: Calendar = .current) {
        self.calendar = calendar
    }
    
    func isDateInToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }
    
    func startOfMonth(for date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
    }
    
    func addMonths(_ value: Int, to date: Date) -> Date? {
        calendar.date(byAdding: .month, value: value, to: date)
    }
    
    func addDays(_ value: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: value, to: date)!
    }
    
    func component(_ component: Calendar.Component, from date: Date) -> Int {
        calendar.component(component, from: date)
    }
    
    func isDate(_ date: Date, equalTo otherDate: Date, toGranularity component: Calendar.Component) -> Bool {
        calendar.isDate(date, equalTo: otherDate, toGranularity: component)
    }
}
