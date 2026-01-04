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
    sleep(1)
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

        // Allow animations to settle
        sleep(1)

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
    sleep(1)

    // Capture Open State (Explicitly named)
    let openScreenshot = captureWindow()
    ScreenshotCapture.save(screenshot: openScreenshot, name: "sidebar_open", to: self)

    // Toggle Sidebar
    let toggleButton = app.buttons.matching(
      NSPredicate(format: "label CONTAINS 'Sidebar' OR identifier CONTAINS 'sidebar'"),
    ).firstMatch

    if toggleButton.exists {
      toggleButton.click()
      sleep(1)

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
