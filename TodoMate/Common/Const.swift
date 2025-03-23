//
//  Const.swift
//  TodoMate
//
//  Created by hs on 12/28/24.
//

import Foundation

enum Const {}

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
    static let MESSAGE = "messages"
    static let GROUP = "groups"
  }
}

extension Const {
  #if DEBUG || PREVIEW
    static let AuthenticatedUserCacheKey = "test-userInfo"
    static let TodoOrderDateKey = "test-todoOrderDate"
    static let TodoOrderKey = "test-todoOrder"
    static let UserGroupCacheKey = "test-userGroupCache"
  #else
    static let AuthenticatedUserCacheKey = "userInfo"
    static let TodoOrderDateKey = "todoOrderDate"
    static let TodoOrderKey = "todoOrder"
    static let UserGroupCacheKey = "userGroupCache"
  #endif
}

typealias FireStore = Const.FireStore
