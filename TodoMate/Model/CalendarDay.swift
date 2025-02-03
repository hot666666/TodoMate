//
//  CalendarDay.swift
//  TodoMate
//
//  Created by hs on 8/13/24.
//

import Foundation
import SwiftUI

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
        dayString == " 1"
    }
    
    var dayString: String {
        let dateString = date.toDayString()
        return dateString.count == 1 ? " " + dateString : dateString
    }
    
    var monthString: String {
        date.toMonthString()
    }
    
    var foregroundColor: Color {
        if isToday {
            return .red
        }
        
        if isCurrentMonth {
            return .primary
        } else {
            return .secondary
        }
    }
}

