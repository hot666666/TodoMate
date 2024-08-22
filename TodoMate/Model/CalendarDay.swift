//
//  CalendarDay.swift
//  TodoMate
//
//  Created by hs on 8/13/24.
//

import Foundation

enum CalendarMonthType {
    case curr
    case prev
    case next
}

enum CalendarDateType {
    case `default`
    case today
    case selected
}

struct CalendarDay: Identifiable, Hashable {
    let id: Int
    let date: Date
    var monthType: CalendarMonthType
    var dateType: CalendarDateType
}

extension CalendarDay {
    var isCurrentMonth: Bool {
        monthType == .curr
    }
    
    var isToday: Bool {
        dateType == .today
    }
    
    var isFirstDay: Bool {
        dayString == "1"
    }
    
    var dayString: String {
        date.toDayString()
    }
    
    var monthString: String {
        date.toMonthString()
    }
}

