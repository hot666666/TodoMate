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

  private func launchApp(args: [String] = []) {
    app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "-useMockContainer"] + args
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
    launchApp() // Default scenario seeds data
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

  // MARK: - Settings in 3 States

  @MainActor
  func testCaptureSettings_Guest() {
    launchApp(args: ["-scenario", "guest"])
    captureScreen(.settings)
  }

  @MainActor
  func testCaptureSettings_NoGroup() {
    launchApp(args: ["-scenario", "no_group"])
    captureScreen(.settings)
  }

  @MainActor
  func testCaptureSettings_GroupUser() {
    launchApp(args: ["-scenario", "group_user"])
    captureScreen(.settings)
  }

  // MARK: - Group in 3 States

  @MainActor
  func testCaptureLogin() {
    // Guest accessing Group -> Login View
    launchApp(args: ["-scenario", "guest"])
    captureScreen(.login)
  }

  @MainActor
  func testCaptureNoGroups() {
    // Logged in (No Group) accessing Group -> No Groups View
    launchApp(args: ["-scenario", "no_group"])
    captureScreen(.noGroups)
  }

  @MainActor
  func testCaptureGroupFeed() {
    // Logged in (Group) accessing Group -> Feed View
    launchApp(args: ["-scenario", "group_user"])
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
