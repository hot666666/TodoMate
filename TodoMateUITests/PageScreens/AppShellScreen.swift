import XCTest

@MainActor
struct AppShellScreen {
  private let app: XCUIApplication
  private let selectors: any ProjectJourneySelectorsSet

  init(
    app: XCUIApplication,
    selectors: any ProjectJourneySelectorsSet = ProjectJourneySelectors()
  ) {
    self.app = app
    self.selectors = selectors
  }

  func assertLoaded(file: StaticString = #filePath, line: UInt = #line) {
    let shell = selectors.appShell.element(in: app)
    if !shell.waitForExistence(timeout: 2) {
      app.descendants(matching: .statusItem)["checklist"].firstMatch.waitAndClick(
        file: file,
        line: line
      )
      app.menuItems["TodoMate 열기"].firstMatch.waitAndClick(file: file, line: line)
    }
    shell.assertExists(file: file, line: line)
    selectors.createProjectButton.element(in: app).assertExists(file: file, line: line)
  }

  func createProject(
    named name: String,
    expectedID: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> ProjectWorkspaceScreen {
    selectors.createProjectButton.element(in: app).waitAndClick(file: file, line: line)
    let nameField = selectors.projectNameField.element(in: app).assertExists(file: file, line: line)
    nameField.click()
    nameField.typeText(name)
    selectors.createConfirmButton.element(in: app).waitAndClick(file: file, line: line)

    let workspace = ProjectWorkspaceScreen(app: app, selectors: selectors)
    workspace.assertLoaded(projectName: name, expectedProjectID: expectedID, file: file, line: line)
    return workspace
  }

  func assertRestoredProject(
    id: String,
    name: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> ProjectWorkspaceScreen {
    selectors.projectRow(id: id).element(in: app).assertExists(file: file, line: line)
    let workspace = ProjectWorkspaceScreen(app: app, selectors: selectors)
    workspace.assertLoaded(projectName: name, expectedProjectID: id, file: file, line: line)
    return workspace
  }
}
