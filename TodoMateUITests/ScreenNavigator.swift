//
//  ScreenNavigator.swift
//  TodoMateUITests
//
//  Helper for navigating to specific screens in UI tests.
//

import XCTest

/// Helper for navigating to specific screens during UI tests.
struct ScreenNavigator {
  let app: XCUIApplication

  /// Navigates to the specified screen type.
  /// - Parameter screen: The target screen to navigate to
  func navigate(to screen: ScreenType) {
    switch screen {
    case .personalBoard:
      navigateToPersonalBoard()

    case .personalCalendar:
      navigateToPersonalCalendar()

    case .groupFeed:
      navigateToGroupFeed()

    case .memo:
      navigateToMemo()

    case .profile:
      navigateToProfile()

    case .noGroupsView:
      navigateToNoGroupsView()

    case .addTaskOverlay:
      navigateToAddTaskOverlay()
    }
  }

  // MARK: - Navigation Logic

  private func navigateToPersonalBoard() {
    print("    -> Navigating to Personal Board...")

    let sidebarTodoButton = app.buttons["sidebar_todo"].firstMatch
    if sidebarTodoButton.waitForExistence(timeout: 3.0) {
      sidebarTodoButton.click()
    }

    // Switch to Board View using radio button
    let boardButton = app.radioButtons["viewMode_board"].firstMatch
    if !boardButton.waitForExistence(timeout: 3.0) {
      // Debugging: Print hierarchy if button is missing
      print("⚠️ 'viewMode_board' radio button not found. Dumping hierarchy snippet:")
      print(app.toolbars.debugDescription)
      XCTFail("⚠️ 'viewMode_board' radio button not found. Is the toolbar visible?")
      return
    }
    boardButton.click()
  }

  private func navigateToPersonalCalendar() {
    print("    -> Navigating to Personal Calendar...")
    // User explicitly said: app.radioButtons["viewMode_calendar"].firstMatch.click()
    let calendarButton = app.radioButtons["viewMode_calendar"].firstMatch
    if calendarButton.exists {
      calendarButton.click()
    } else {
      XCTFail("⚠️ 'viewMode_calendar' radio button not found.")
    }
  }

  private func navigateToMemo() {
    print("    -> Navigating to Memo...")
    let memoButton = app.buttons["sidebar_memo"].firstMatch
    if memoButton.exists {
      memoButton.click()
    } else {
      XCTFail("⚠️ 'sidebar_memo' not found.")
    }
    sleep(1)
  }

  private func navigateToProfile() {
    print("    -> Navigating to Profile/Settings...")
    // User explicitly said: app.buttons["sidebar_profile"].firstMatch.click()
    let profileLink = app.buttons["sidebar_profile"].firstMatch
    if profileLink.exists {
      profileLink.click()
    } else {
      XCTFail("⚠️ 'sidebar_profile' not found.")
    }
  }

  private func navigateToGroupFeed() {
    print("    -> Navigating to Group Feed...")
    // Assuming "Design Team" exists as per SidebarView hardcoded item
    let groupButton = app.buttons["sidebar_group_design-team"].firstMatch
    if groupButton.exists {
      groupButton.click()
    } else {
      XCTFail("⚠️ 'sidebar_group_design-team' not found.")
    }
    sleep(2)
  }

  private func navigateToNoGroupsView() {
    print("    -> Navigating to 'No Groups Joined'...")
    let noGroupsButton = app.buttons["sidebar_noGroups"].firstMatch
    if noGroupsButton.exists {
      noGroupsButton.click()
    } else {
      XCTFail("⚠️ 'sidebar_noGroups' not found.")
    }
    sleep(1)
  }

  private func navigateToAddTaskOverlay() {
    print("    -> Navigating to Add Task Overlay...")
    // First ensure we're on personal board to have the + button
    navigateToPersonalBoard()

    // Click + button using accessibility identifier
    let addButton = app.buttons["addTaskButton"].firstMatch
    if addButton.exists {
      addButton.click()
    } else {
      // Fallback
      let toolbarButton = app.toolbars.buttons["addTaskButton"]
      if toolbarButton.exists {
        toolbarButton.click()
      } else {
        XCTFail("⚠️ 'addTaskButton' not found.")
      }
    }

    // CRITICAL: Wait for the sheet to appear!
    // "New Task" is the title in AddTaskSheet
    let newTaskTitle = app.staticTexts["New Task"]
    if !newTaskTitle.waitForExistence(timeout: 5.0) {
      XCTFail("⚠️ Add Task Overlay did not appear within 5 seconds.")
    }
    sleep(1)
  }

  func closeAddTaskOverlay() {
    let closeButton = app.buttons["xmark.circle.fill"].firstMatch
    if closeButton.exists {
      closeButton.click()
      sleep(1) // Wait for animation
    }
  }
}
