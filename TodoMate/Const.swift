//
//  Const.swift
//  TodoMate
//
//  Created by hs on 12/28/24.
//

import Foundation

enum Const { }

extension Const {
    enum TodoDatePopoverFrame {
        static let WIDTH: CGFloat = 250
        static let HEIGHT: CGFloat = 350
    }
}
extension Const {
    enum CalendarView {
        static let WEEKDAYS: [String] = ["일", "월", "화", "수", "목", "금", "토"]
    }
}
extension Const {
    enum FireStore {
        static let USER = "users"
        static let TODO = "todos"
        static let CHAT = "chats"
    }
}
extension Const {
    static let UserInfoKey = "userInfo"
}

typealias FireStore = Const.FireStore
