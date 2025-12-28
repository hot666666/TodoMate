//
//  TodoMateUITests.swift
//  TodoMateUITests
//
//  Created by hs on 12/28/25.
//

import XCTest

final class TodoMateUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  override func tearDownWithError() throws {}

  @MainActor
  func testLaunchPerformance() throws {
    measure(metrics: [XCTApplicationLaunchMetric()]) {
      XCUIApplication().launch()
    }
  }
}
