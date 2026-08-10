public enum AccessibilityID {
  public enum AppShell {
    public static let root = "app.shell"
  }

  public enum ProjectSidebar {
    public static let root = "project.sidebar"
    public static let createButton = "project.sidebar.create"
    public static let createNameField = "project.create.name"
    public static let createConfirmButton = "project.create.confirm"

    public static func row(_ projectID: String) -> String {
      "project.sidebar.row.\(projectID)"
    }
  }

  public enum ProjectWorkspace {
    public static let root = "project.workspace"
    public static let title = "project.workspace.title"
    public static let todoSectionButton = "project.workspace.section.todo"
    public static let memoSectionButton = "project.workspace.section.memo"
    public static let chatSectionButton = "project.workspace.section.chat"
  }

  public enum ProjectTodo {
    public static let root = "project.todo"
  }
}
