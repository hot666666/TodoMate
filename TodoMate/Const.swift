//
//  Const.swift
//  TodoMate
//
//  Created by hs on 8/13/24.
//

import Foundation

enum Const { }

extension Const {
    enum DateSettingViewFrame {
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
        static let USER = "todomates"
        static let TODO = "todos"
        static let CHAT = "chats"
    }
}

typealias FireStore = Const.FireStore

extension Const {
    /// variable used in updating Chat
    static let Signature = UUID().uuidString
}
