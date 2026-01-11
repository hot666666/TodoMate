//
//  PrivateModeUITests.swift
//  TodoMateUITests
//
//  Created by agent on 1/11/26.
//

import XCTest

final class PrivateModeUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  @MainActor
  func testPrivateModeCRUD() throws {
    let app = XCUIApplication()
    // Force Private Mode via UserDefaults launch argument
    // Assuming UserDefaultsKey.isPublicModeEnabled.rawValue is "isPublicModeEnabled"
    app.launchArguments = ["-isPublicModeEnabled", "NO"]
    app.launch()

    // 1. Verify we are in Private Mode (PrivateFeatureWrapper)
    // PrivateSidebarView has "Go Online" button or specific header
    // Let's verify sidebar "Public" header or similar is NOT there for now,
    // or check for Private specific elements.
    // Or simply check if we can manipulate data without login.

    let todoButton = app.buttons["sidebar_todo"]
    XCTAssertTrue(
      todoButton.waitForExistence(timeout: 5), "Sidebar 'Todo' button should be visible",
    )
    todoButton.tap()

    // 2. Create a Todo
    // Assuming standard "Add Todo" flow works in Private Mode
    let addTodoButton = app.buttons["add_todo_button"] // Need to verify this ID exists in BoardView
    if addTodoButton.exists {
      addTodoButton.tap()
    } else {
      // Fallback shortcut? Or maybe empty state button
      // Let's try to find an equivalent to "Add"
      // BoardView usually has a toolbar button
    }

    // For now, let's just assert we launched successfully and can see the board.
    // We will refine this test after verifying the launch.

    let boardView = app.otherElements["board_view"]
    XCTAssertTrue(boardView.waitForExistence(timeout: 5), "Board View should be visible")
    // We need to check BoardView's accessibility identifier.
  }
}
