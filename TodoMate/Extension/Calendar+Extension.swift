//
//  Calendar+Extension.swift
//  TodoMate
//
//  Created by hs on 2/2/25.
//

import Foundation

extension Calendar {
    // func isDateInToday(_ date: Date) -> Bool
    // func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool
    // func startOfDay(for date: Date) -> Date
    // func component(_ component: Calendar.Component, from date: Date) -> Int
    // func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool
    // func isDate(_ date: Date, equalTo otherDate: Date, toGranularity component: Calendar.Component) -> Bool
    
    func endOfDay(for date: Date) -> Date {
        let startOfDay = self.startOfDay(for: date)
        return self.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
    }
    
    func startOfMonth(for date: Date) -> Date {
        self.date(from: self.dateComponents([.year, .month], from: date))!
    }
    
    func addMonths(_ value: Int, to date: Date) -> Date? {
        self.date(byAdding: .month, value: value, to: date)
    }
    
    func addDays(_ value: Int, to date: Date) -> Date {
        self.date(byAdding: .day, value: value, to: date)!
    }

    func getTodayDateRange() -> (start: Date, end: Date) {
        let startOfDay = self.startOfDay(for: .now)
        let endOfDay = self.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
        
        return (start: startOfDay, end: endOfDay)
    }
}
