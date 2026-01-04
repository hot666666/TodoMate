//
//  ScreenshotTests.swift
//  TodoMateUITests
//
//  Screenshot capture tests for UI verification.
//  Uses ScreenType, ScreenNavigator, and ScreenshotCapture for systematic capture.
//

import XCTest

final class ScreenshotTests: XCTestCase {
  let app = XCUIApplication()
  lazy var navigator = ScreenNavigator(app: app)

  override func setUpWithError() throws {
    continueAfterFailure = false
    app.launchEnvironment["BYPASS_AUTH"] = "1"
    app.launch()
  }

  // MARK: - Systematic Screen Capture

  @MainActor
  func testFullScreenshotFlow() throws {
    // 1. Capture Default Window State (Initial Launch)
    // Wait for App Launch
    XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 10), "App window should appear")

    let defaultScreenshot = captureWindow()
    ScreenshotCapture.save(screenshot: defaultScreenshot, name: "window_default", to: self)

    // 2. Iterate and Capture Main Screens
    let screensToCapture: [ScreenType] = [
      .personalBoard,
      .personalCalendar,
      .addTaskOverlay,
      .memo,
      .groupFeed,
      .noGroupsView,
      .profile,
    ]

    for screenType in screensToCapture {
      print("📸 Navigating to \(screenType)...")
      XCTContext.runActivity(named: "Capture \(screenType)") { activity in
        navigator.navigate(to: screenType)

        // Navigation methods now include explicit waits, so extra sleep is removed.

        // Verify specific elements if needed
        if screenType == .noGroupsView {
          let noGroupsView = app.scrollViews["GroupFeedNoGroupView"]
          XCTAssertTrue(
            noGroupsView.waitForExistence(timeout: 5), "GroupFeedNoGroupView should exist",
          )
        }

        let screenshot = captureWindow()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(screenType.rawValue)_0"
        attachment.lifetime = .keepAlways
        activity.add(attachment)

        if screenType == .addTaskOverlay {
          navigator.closeAddTaskOverlay()
        }
      }
    }

    // 3. Capture Sidebar Toggle (Destructive/State-changing action, do last)
    // Navigate back to a known state (Personal Board)
    navigator.navigate(to: .personalBoard)
    // Removed sleep(1) here as navigate now waits.

    // Capture Open State (Explicitly named)
    let openScreenshot = captureWindow()
    ScreenshotCapture.save(screenshot: openScreenshot, name: "sidebar_open", to: self)

    // Toggle Sidebar
    let toggleButton = app.buttons.matching(
      NSPredicate(format: "label CONTAINS 'Sidebar' OR identifier CONTAINS 'sidebar'"),
    ).firstMatch

    if toggleButton.exists {
      toggleButton.click()

      // Wait for Sidebar to Close (Wait for 'sidebar_memo' to disappear)
      let sidebarElement = app.buttons["sidebar_memo"].firstMatch
      if sidebarElement.exists {
        let doesNotExist = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: doesNotExist, object: sidebarElement)
        _ = XCTWaiter.wait(for: [expectation], timeout: 2.0)
      } else {
        // If it didn't exist, maybe it was already closed or transient.
        // Just verify window still exists.
        _ = app.windows.firstMatch.waitForExistence(timeout: 2.0)
      }

      let closedScreenshot = captureWindow()
      ScreenshotCapture.save(screenshot: closedScreenshot, name: "sidebar_closed", to: self)
    } else {
      XCTFail("Sidebar toggle button not found")
    }
  }

  // MARK: - Helper Methods

  private func captureWindow() -> XCUIScreenshot {
    let window = app.windows.firstMatch
    if window.exists {
      return window.screenshot()
    }
    return app.screenshot()
  }
}
