//
//  ScreenType.swift
//  TodoMateUITests
//
//  Defines capturable screen types for screenshot-based UI verification.
//

import Foundation

/// Enum defining all screens that can be captured for UI verification.
/// Each case represents a distinct screen state that can be navigated to and captured.
enum ScreenType: String, CaseIterable {
  // MARK: - Personal Views

  case personalBoard = "personal_board"
  case personalCalendar = "personal_calendar"

  // MARK: - Group Views

  case groupFeed = "group_feed"
  case noGroupsJoined = "no_groups_joined"

  // MARK: - Overlays

  case addTaskOverlay = "add_task_overlay"

  /// The filename to use when saving screenshots
  var screenshotFilename: String {
    "\(rawValue).png"
  }

  /// Human-readable description for logging
  var description: String {
    switch self {
    case .personalBoard:
      "Personal Board View"
    case .personalCalendar:
      "Personal Calendar View"
    case .groupFeed:
      "Group Feed View"
    case .noGroupsJoined:
      "No Groups Joined View"
    case .addTaskOverlay:
      "Add Task Overlay"
    }
  }
}
