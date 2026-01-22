//
//  ScreenType.swift
//  TodoMateUITests
//
//  Created by hs on 2026/01/06.
//

import Foundation

/// 스크린샷을 캡처할 화면 타입 정의
enum ScreenType: String, CaseIterable {
  case personalBoard = "personal_board"
  case personalCalendar = "personal_calendar"
  case memo
  case groupFeed = "group_feed"
  case noGroups = "no_groups"
  case login
  case settings
  case trash

  /// 해당 화면의 메인 뷰 accessibility identifier
  var accessibilityIdentifier: String {
    switch self {
    case .personalBoard: "personalBoardView"
    case .personalCalendar: "personalCalendarView"
    case .memo: "memoView"
    case .groupFeed: "groupFeedView"
    case .noGroups: "GroupFeedNoGroupView"
    case .login: "loginView"
    case .settings: "settingView"
    case .trash: "trashView"
    }
  }

  /// 사이드바에서 탭해야 하는 요소의 identifier
  var sidebarIdentifier: String? {
    switch self {
    case .personalBoard, .personalCalendar: "sidebar_todo"
    case .memo: "sidebar_memo"
    case .groupFeed, .noGroups: "sidebar_group"
    case .settings: "sidebar_profile"
    case .login: "sidebar_group"
    case .trash: "sidebar_trash"
    }
  }

  /// Board/Calendar 전환이 필요한 화면인지
  var requiresViewModeSwitch: Bool {
    switch self {
    case .personalBoard, .personalCalendar: true
    default: false
    }
  }

  /// 필요한 ViewMode (Board/Calendar)
  var viewMode: String? {
    switch self {
    case .personalBoard: "board"
    case .personalCalendar: "calendar"
    default: nil
    }
  }
}
