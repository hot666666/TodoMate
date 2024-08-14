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

struct CalendarDay: Identifiable {
    let id: Int
    let date: Date
    var monthType: CalendarMonthType
    var dateType: CalendarDateType

    var isCurrentMonth: Bool {
        monthType == .curr
    }
}
