import XCTest

@MainActor
final class ProjectJourneyUITests: XCTestCase {
  private let projectID = "ui-project-1"
  private let projectName = "Daily"
  private var databaseID: String!
  private var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    databaseID = UUID().uuidString
    app = makeApplication(resetDatabase: true)
  }

  override func tearDownWithError() throws {
    app?.terminate()
  }

  func testCreateSelectTodoAndRestoreAfterRelaunch() {
    app.launch()
    let shell = AppShellScreen(app: app)
    shell.assertLoaded()
    _ = shell.createProject(named: projectName, expectedID: projectID)

    app.terminate()
    app = makeApplication(resetDatabase: false)
    app.launch()

    let restoredShell = AppShellScreen(app: app)
    restoredShell.assertLoaded()
    _ = restoredShell.assertRestoredProject(id: projectID, name: projectName)
  }

  private func makeApplication(resetDatabase: Bool) -> XCUIApplication {
    let application = XCUIApplication()
    application.launchArguments += [
      "--ui-testing-project-database-id", databaseID,
      "--ui-testing-project-id", projectID,
    ]
    if resetDatabase {
      application.launchArguments.append("--ui-testing-reset-project-database")
    }
    return application
  }
}
