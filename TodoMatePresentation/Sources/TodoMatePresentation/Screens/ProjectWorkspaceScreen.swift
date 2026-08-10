import ComposableArchitecture
import SwiftUI
import TodoMateUITestContracts

struct ProjectWorkspaceScreen: View {
  let store: StoreOf<ProjectWorkspaceFeature>

  var body: some View {
    ProjectWorkspaceView(
      projectName: store.project.name.value,
      lifecycleLabel: store.project.lifecycle == .local ? "Local" : "",
      selectedSection: store.selectedSection,
      onSectionSelected: { store.send(.view(.sectionSelected($0))) },
    )
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier(AccessibilityID.ProjectWorkspace.root)
  }
}

private struct ProjectWorkspaceView: View {
  let projectName: String
  let lifecycleLabel: String
  let selectedSection: ProjectWorkspaceFeature.State.Section
  let onSectionSelected: (ProjectWorkspaceFeature.State.Section) -> Void

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text(projectName)
            .font(.title2.bold())
            .accessibilityIdentifier(AccessibilityID.ProjectWorkspace.title)
          Text(lifecycleLabel)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
        Picker("Section", selection: Binding(
          get: { selectedSection },
          set: { section in onSectionSelected(section) },
        )) {
          Text("Todo").tag(ProjectWorkspaceFeature.State.Section.todo)
            .accessibilityIdentifier(AccessibilityID.ProjectWorkspace.todoSectionButton)
          Text("Memo").tag(ProjectWorkspaceFeature.State.Section.memo)
            .accessibilityIdentifier(AccessibilityID.ProjectWorkspace.memoSectionButton)
          Text("Chat").tag(ProjectWorkspaceFeature.State.Section.chat)
            .accessibilityIdentifier(AccessibilityID.ProjectWorkspace.chatSectionButton)
        }
        .pickerStyle(.segmented)
        .frame(width: 240)
      }
      .padding()

      Divider()

      switch selectedSection {
      case .todo:
        ContentUnavailableView(
          "Todo",
          systemImage: "checklist",
          description: Text("이 Project의 Todo section입니다."),
        )
        .accessibilityIdentifier(AccessibilityID.ProjectTodo.root)
      case .memo:
        ContentUnavailableView("Memo", systemImage: "note.text")
      case .chat:
        ContentUnavailableView("Chat", systemImage: "bubble.left.and.bubble.right")
      }
    }
  }
}
