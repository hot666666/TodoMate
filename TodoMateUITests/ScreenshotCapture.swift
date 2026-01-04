//
//  ScreenshotCapture.swift
//  TodoMateUITests
//
//  Utility for capturing and saving screenshots during UI tests.
//  Screenshots are saved as XCTAttachment and extracted via xcresulttool.
//

import XCTest

/// Utility enum for screenshot capture and saving.
enum ScreenshotCapture {
  /// Saves a screenshot for a specific screen type.
  /// - Parameters:
  ///   - screenshot: The captured screenshot
  ///   - screenType: The type of screen being captured
  ///   - testCase: The test case to attach the screenshot to
  static func save(
    screenshot: XCUIScreenshot, for screenType: ScreenType, to testCase: XCTestCase,
  ) {
    save(screenshot: screenshot, name: screenType.rawValue, to: testCase)
  }

  /// Saves a screenshot with a custom name.
  /// - Parameters:
  ///   - screenshot: The captured screenshot
  ///   - name: The name for the screenshot
  ///   - testCase: The test case to attach the screenshot to
  static func save(screenshot: XCUIScreenshot, name: String, to testCase: XCTestCase) {
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = "\(name)_0"
    attachment.lifetime = .keepAlways
    testCase.add(attachment)

    print("📸 Screenshot saved: \(name)")
  }
}
