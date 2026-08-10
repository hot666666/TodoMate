import XCTest

enum UITestWait {
  static let normal: TimeInterval = 8
}

extension XCUIElement {
  @MainActor
  @discardableResult
  func assertExists(
    timeout: TimeInterval = UITestWait.normal,
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> Self {
    XCTAssertTrue(
      waitForExistence(timeout: timeout),
      "Expected element to exist: \(self)",
      file: file,
      line: line
    )
    return self
  }

  @MainActor
  func waitAndClick(
    timeout: TimeInterval = UITestWait.normal,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertExists(timeout: timeout, file: file, line: line)
    let expectation = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "hittable == true"),
      object: self
    )
    let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
    XCTAssertEqual(result, .completed, "Expected element to become hittable", file: file, line: line)
    guard result == .completed else { return }
    click()
  }
}
