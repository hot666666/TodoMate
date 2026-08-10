import XCTest

@MainActor
struct ProjectWorkspaceScreen {
  private let app: XCUIApplication
  private let selectors: any ProjectJourneySelectorsSet

  init(app: XCUIApplication, selectors: any ProjectJourneySelectorsSet) {
    self.app = app
    self.selectors = selectors
  }

  func assertLoaded(
    projectName: String,
    expectedProjectID: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    selectors.workspace.element(in: app).assertExists(file: file, line: line)
    let title = selectors.workspaceTitle.element(in: app).assertExists(file: file, line: line)
    XCTAssertEqual(title.label, projectName, file: file, line: line)
    selectors.projectRow(id: expectedProjectID).element(in: app).assertExists(file: file, line: line)
    selectors.todoSection.element(in: app).assertExists(file: file, line: line)
  }
}
