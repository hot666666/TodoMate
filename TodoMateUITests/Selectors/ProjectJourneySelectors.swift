import TodoMateUITestContracts

protocol ProjectJourneySelectorsSet {
  var appShell: Selector { get }
  var createProjectButton: Selector { get }
  var projectNameField: Selector { get }
  var createConfirmButton: Selector { get }
  var workspace: Selector { get }
  var workspaceTitle: Selector { get }
  var todoSection: Selector { get }
  func projectRow(id: String) -> Selector
}

struct ProjectJourneySelectors: ProjectJourneySelectorsSet {
  let appShell = Selector(
    strategy: .anyByID,
    identifier: AccessibilityID.AppShell.root,
    description: "Project app shell"
  )
  let createProjectButton = Selector(
    strategy: .buttonByID,
    identifier: AccessibilityID.ProjectSidebar.createButton,
    description: "Create Project button"
  )
  let projectNameField = Selector(
    strategy: .textFieldByID,
    identifier: AccessibilityID.ProjectSidebar.createNameField,
    description: "Project name field"
  )
  let createConfirmButton = Selector(
    strategy: .buttonByID,
    identifier: AccessibilityID.ProjectSidebar.createConfirmButton,
    description: "Create Project confirmation"
  )
  let workspace = Selector(
    strategy: .anyByID,
    identifier: AccessibilityID.ProjectWorkspace.root,
    description: "Project Workspace"
  )
  let workspaceTitle = Selector(
    strategy: .staticTextByID,
    identifier: AccessibilityID.ProjectWorkspace.title,
    description: "Project Workspace title"
  )
  let todoSection = Selector(
    strategy: .anyByID,
    identifier: AccessibilityID.ProjectTodo.root,
    description: "Project Todo section"
  )

  func projectRow(id: String) -> Selector {
    Selector(
      strategy: .buttonByID,
      identifier: AccessibilityID.ProjectSidebar.row(id),
      description: "Project row"
    )
  }
}
