import XCTest

@MainActor
final class ProjectJourneyUITests: XCTestCase {
  private let projectID = "ui-project-1"
  private let projectName = "Daily"
  private let todoID = "ui-todo-1"
  private let todoTitle = "First Todo"
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
    let workspace = shell.createProject(named: projectName, expectedID: projectID)
    workspace.createTodo(titled: todoTitle, expectedID: todoID)

    app.terminate()
    app = makeApplication(resetDatabase: false)
    app.launch()

    let restoredShell = AppShellScreen(app: app)
    restoredShell.assertLoaded()
    let restoredWorkspace = restoredShell.assertRestoredProject(id: projectID, name: projectName)
    restoredWorkspace.assertTodo(id: todoID, title: todoTitle)
  }

  private func makeApplication(resetDatabase: Bool) -> XCUIApplication {
    let application = XCUIApplication()
    application.launchArguments += [
      "-ApplePersistenceIgnoreState", "YES",
      "--ui-testing-project-database-id", databaseID,
      "--ui-testing-project-id", projectID,
      "--ui-testing-todo-id", todoID,
    ]
    if resetDatabase {
      application.launchArguments.append("--ui-testing-reset-project-database")
    }
    return application
  }
}
