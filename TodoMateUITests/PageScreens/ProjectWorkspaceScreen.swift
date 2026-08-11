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
    line: UInt = #line,
  ) {
    selectors.workspace.element(in: app).assertExists(file: file, line: line)
    let title = selectors.workspaceTitle.element(in: app).assertExists(file: file, line: line)
    let displayedTitle = title.label.isEmpty ? title.value as? String : title.label
    XCTAssertEqual(displayedTitle, projectName, file: file, line: line)
    selectors.projectRow(id: expectedProjectID).element(in: app).assertExists(file: file, line: line)
    selectors.todoSection.element(in: app).assertExists(file: file, line: line)
  }

  func createTodo(
    titled title: String,
    expectedID: String,
    file: StaticString = #filePath,
    line: UInt = #line,
  ) {
    let titleField = selectors.todoTitleField.element(in: app)
      .assertExists(file: file, line: line)
    titleField.replaceText(with: title, file: file, line: line)
    selectors.createTodoButton.element(in: app).waitAndClick(file: file, line: line)
    assertTodo(id: expectedID, title: title, file: file, line: line)
  }

  func assertTodo(
    id: String,
    title: String,
    file: StaticString = #filePath,
    line: UInt = #line,
  ) {
    let row = selectors.todoRow(id: id).element(in: app).assertExists(file: file, line: line)
    let displayedTitle = row.label.isEmpty ? row.value as? String : row.label
    XCTAssertEqual(displayedTitle, title, file: file, line: line)
  }
}
