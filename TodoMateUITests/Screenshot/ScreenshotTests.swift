//
//  ScreenshotTests.swift
//  TodoMateUITests
//
//  Created by hs on 2026/01/06.
//

import XCTest

/// UI 스크린샷 캡처 테스트
final class ScreenshotTests: XCTestCase {
  var app: XCUIApplication!
  var navigator: ScreenNavigator!

  // MARK: - Setup & Teardown

  override func setUpWithError() throws {
    continueAfterFailure = false
    // App is launched per test method to support scenarios
  }

  override func tearDownWithError() throws {
    app = nil
    navigator = nil
  }

  private func launchApp(scenario: String = "group_user") {
    app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "-scenario", scenario]
    app.launch()
    app.activate()

    // 앱 윈도우가 활성화될 때까지 대기
    let window = app.windows.firstMatch
    XCTAssertTrue(window.waitForExistence(timeout: 10), "App window should exist")

    navigator = ScreenNavigator(app: app)
  }

  // MARK: - Individual Screen Tests

  @MainActor
  func testCapturePersonalBoard() {
    launchApp()
    captureScreen(.personalBoard)
  }

  @MainActor
  func testCapturePersonalCalendar() {
    launchApp()
    captureScreen(.personalCalendar)
  }

  @MainActor
  func testCaptureMemo() {
    launchApp()
    captureScreen(.memo)
  }

  @MainActor
  func testCaptureSettings() {
    launchApp()
    captureScreen(.settings)
  }

  @MainActor
  func testCaptureNoGroups() {
    launchApp(scenario: "no_group_user")
    captureScreen(.noGroups)
  }

  @MainActor
  func testCaptureGroupFeed() {
    launchApp(scenario: "group_user")
    captureScreen(.groupFeed)
  }

  // MARK: - Private Helpers

  private func captureScreen(_ screen: ScreenType) {
    print("\n🎯 Capturing: \(screen.rawValue)")

    navigator.navigate(to: screen)

    // 화면 안정화 대기
    Thread.sleep(forTimeInterval: 0.5)

    let screenshot = app.windows.firstMatch.screenshot()
    ScreenshotCapture.save(screenshot: screenshot, for: screen, to: self)
  }
}
