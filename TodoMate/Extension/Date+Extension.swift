//
//  Date+Extension.swift
//  TodoMate
//
//  Created by hs on 8/13/24.
//

import Foundation

extension Date {
    func toYYYYMMDDString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter.string(from: self)
    }
    
    func toYearMonthString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 M월"
        return dateFormatter.string(from: self)
    }
    
    func toDayString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        return dateFormatter.string(from: self)
    }
}
