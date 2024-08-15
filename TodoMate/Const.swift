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
        static let HEIGHT: CGFloat = 500
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
    }
}

typealias FireStore = Const.FireStore

