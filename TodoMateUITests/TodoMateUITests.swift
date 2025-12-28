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

  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  @MainActor
  func testAppInitializesWithMainContent() throws {
    let app = XCUIApplication()
    app.launch()

    // macOS에서 앱이 제대로 실행되었는지 확인
    let launched = app.wait(for: .runningForeground, timeout: 10)
    XCTAssertTrue(launched, "앱이 foreground에서 실행되어야 합니다")

    // 메인 콘텐츠가 나타나야 함 (로딩 인디케이터가 아니라)
    let mainContent = app.staticTexts["메인_콘텐츠"]

    // 최대 5초 대기 후 메인 콘텐츠 확인
    XCTAssertTrue(mainContent.waitForExistence(timeout: 5), "메인 콘텐츠가 표시되어야 합니다")
  }

  @MainActor
  func testLaunchPerformance() throws {
    measure(metrics: [XCTApplicationLaunchMetric()]) {
      XCUIApplication().launch()
    }
  }
}
