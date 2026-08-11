import ComposableArchitecture
import SwiftUI
import TodoMateDomain
import TodoMateUITestContracts

struct ProjectWorkspaceScreen: View {
  let store: StoreOf<ProjectWorkspaceFeature>

  var body: some View {
    ProjectWorkspaceView(
      projectName: store.project.name.value,
      lifecycleLabel: store.project.lifecycle == .local ? "Local" : "",
      selectedSection: store.selectedSection,
      todos: store.todos,
      todoDraft: store.todoDraft,
      canCreateTodo: store.canCreateTodo,
      todoError: store.todoError,
      onSectionSelected: { store.send(.view(.sectionSelected($0))) },
      onTodoDraftChanged: { store.send(.view(.todoDraftChanged($0))) },
      onCreateTodo: { store.send(.view(.createTodoTapped)) },
    )
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier(AccessibilityID.ProjectWorkspace.root)
    .task(id: store.project.id) {
      await store.send(.view(.task)).finish()
    }
  }
}

private struct ProjectWorkspaceView: View {
  let projectName: String
  let lifecycleLabel: String
  let selectedSection: ProjectWorkspaceFeature.State.Section
  let todos: [ProjectTodo]
  let todoDraft: String
  let canCreateTodo: Bool
  let todoError: String?
  let onSectionSelected: (ProjectWorkspaceFeature.State.Section) -> Void
  let onTodoDraftChanged: (String) -> Void
  let onCreateTodo: () -> Void

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
        ProjectTodoView(
          todos: todos,
          draft: todoDraft,
          canCreate: canCreateTodo,
          error: todoError,
          onDraftChanged: onTodoDraftChanged,
          onCreate: onCreateTodo,
        )
      case .memo:
        ContentUnavailableView("Memo", systemImage: "note.text")
      case .chat:
        ContentUnavailableView("Chat", systemImage: "bubble.left.and.bubble.right")
      }
    }
  }
}

private struct ProjectTodoView: View {
  let todos: [ProjectTodo]
  let draft: String
  let canCreate: Bool
  let error: String?
  let onDraftChanged: (String) -> Void
  let onCreate: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        TextField(
          "첫 Todo를 입력하세요",
          text: Binding(
            get: { draft },
            set: { value in onDraftChanged(value) },
          ),
        )
        .accessibilityIdentifier(AccessibilityID.ProjectTodo.titleField)

        Button("추가", action: onCreate)
          .disabled(!canCreate)
          .accessibilityIdentifier(AccessibilityID.ProjectTodo.createButton)
      }

      if let error {
        Text(error)
          .foregroundStyle(.red)
          .accessibilityIdentifier(AccessibilityID.ProjectTodo.createError)
      }

      if todos.isEmpty {
        ContentUnavailableView("Todo가 없습니다", systemImage: "checklist")
      } else {
        List(todos) { todo in
          Text(todo.title.value)
            .accessibilityIdentifier(AccessibilityID.ProjectTodo.row(todo.id.rawValue))
        }
      }
      Spacer(minLength: 0)
    }
    .padding()
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier(AccessibilityID.ProjectTodo.root)
  }
}
