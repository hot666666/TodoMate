//
//  ScreenNavigator.swift
//  TodoMateUITests
//
//  Helper for navigating to specific screens in UI tests.
//

import XCTest

/// Helper class to navigate to specific screens for screenshot capture.
/// Encapsulates UI element discovery and navigation logic.
@MainActor
final class ScreenNavigator {
  private let app: XCUIApplication

  init(app: XCUIApplication) {
    self.app = app
  }

  /// Navigate to the specified screen type.
  /// - Parameter screenType: The screen to navigate to
  /// - Returns: True if navigation was successful
  @discardableResult
  func navigate(to screenType: ScreenType) -> Bool {
    switch screenType {
    case .personalBoard:
      navigateToPersonalBoard()
    case .personalCalendar:
      navigateToPersonalCalendar()
    case .groupFeed:
      navigateToGroupFeed()
    case .noGroupsJoined:
      navigateToNoGroupsJoined()
    case .addTaskOverlay:
      navigateToAddTaskOverlay()
    }
  }

  // MARK: - Navigation Methods

  private func navigateToPersonalBoard() -> Bool {
    // Click on "Personal" in sidebar if not already selected
    let personalItem = app.staticTexts["Personal"].firstMatch
    if personalItem.exists {
      personalItem.click()
      sleep(1)
    }

    // Ensure board view is selected (not calendar)
    let boardButton = app.buttons.matching(
      NSPredicate(format: "label CONTAINS 'Board' OR label CONTAINS 'list'"),
    ).firstMatch

    if boardButton.exists {
      boardButton.click()
      sleep(1)
    }

    return true
  }

  private func navigateToPersonalCalendar() -> Bool {
    // Click on "Personal" in sidebar if not already selected
    let personalItem = app.staticTexts["Personal"].firstMatch
    if personalItem.exists {
      personalItem.click()
      sleep(1)
    }

    // Click calendar toggle button
    let calendarButton = app.buttons.matching(
      NSPredicate(format: "label CONTAINS 'Calendar' OR label CONTAINS 'calendar'"),
    ).firstMatch

    if calendarButton.exists {
      calendarButton.click()
      sleep(1)
      return true
    }

    return false
  }

  private func navigateToGroupFeed() -> Bool {
    // Find and click a group in sidebar
    let groupItem = app.staticTexts["Design Team"].firstMatch
    if groupItem.exists {
      groupItem.click()
      sleep(1)
      return true
    }
    return false
  }

  private func navigateToNoGroupsJoined() -> Bool {
    let noGroupsItem = app.staticTexts["No Groups Joined"].firstMatch
    if noGroupsItem.exists {
      noGroupsItem.click()
      sleep(1)
      return true
    }

    // Fallback: try cells
    let cellItem = app.cells.staticTexts["No Groups Joined"].firstMatch
    if cellItem.exists {
      cellItem.click()
      sleep(1)
      return true
    }

    return false
  }

  private func navigateToAddTaskOverlay() -> Bool {
    let addButton = app.buttons.matching(
      NSPredicate(format: "label CONTAINS 'plus' OR label CONTAINS 'Add'"),
    ).firstMatch

    if addButton.exists {
      addButton.click()
      sleep(1)
      return true
    }

    return false
  }
}
