//
//  ScreenType.swift
//  TodoMateUITests
//
//  Enum defining capturable screens for UI verification.
//

import Foundation

/// Represents different screens that can be captured for UI verification.
enum ScreenType: String, CaseIterable {
  case personalBoard = "personal_board"
  case personalCalendar = "personal_calendar"
  case groupFeed = "group_feed"
  case noGroupsView = "no_groups_view"
  case addTaskOverlay = "add_task_overlay"
  case memo
  case profile

  /// Human-readable description for logging
  var description: String {
    switch self {
    case .personalBoard: "Personal Todo Board"
    case .personalCalendar: "Personal Calendar"
    case .groupFeed: "Group Feed"
    case .noGroupsView: "No Groups View"
    case .addTaskOverlay: "Add Task Overlay"
    case .memo: "Personal Memo"
    case .profile: "User Profile / Settings"
    }
  }
}
