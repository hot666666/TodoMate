import ComposableArchitecture
import SwiftUI
import TodoMateDomain
import TodoMateUITestContracts

struct ProjectSidebarScreen: View {
  let store: StoreOf<ProjectSidebarFeature>

  var body: some View {
    ProjectSidebarView(
      projects: store.projects,
      selectedProjectID: store.selectedProjectID,
      onCreate: { store.send(.view(.createButtonTapped)) },
      onSelect: { store.send(.view(.projectSelected($0))) },
    )
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier(AccessibilityID.ProjectSidebar.root)
    .sheet(isPresented: Binding(
      get: { store.isCreatePresented },
      set: { isPresented in
        if !isPresented { store.send(.view(.createCancelled)) }
      },
    )) {
      ProjectCreateView(
        name: Binding(
          get: { store.newProjectName },
          set: { store.send(.view(.createNameChanged($0))) },
        ),
        isCreating: store.operation == .creating,
        onCancel: { store.send(.view(.createCancelled)) },
        onConfirm: { store.send(.view(.createConfirmed)) },
      )
    }
  }
}

private struct ProjectSidebarView: View {
  let projects: [Project]
  let selectedProjectID: ProjectID?
  let onCreate: () -> Void
  let onSelect: (ProjectID) -> Void

  var body: some View {
    List {
      Section("Projects") {
        ForEach(projects) { project in
          Button {
            onSelect(project.id)
          } label: {
            Label(project.name.value, systemImage: "folder")
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          .buttonStyle(.plain)
          .listRowBackground(
            selectedProjectID == project.id ? Color.accentColor.opacity(0.18) : Color.clear,
          )
          .accessibilityIdentifier(AccessibilityID.ProjectSidebar.row(project.id.rawValue))
        }
      }
    }
    .safeAreaInset(edge: .bottom) {
      Button(action: onCreate) {
        Label("새 프로젝트", systemImage: "plus")
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .buttonStyle(.plain)
      .padding()
      .accessibilityIdentifier(AccessibilityID.ProjectSidebar.createButton)
    }
  }
}

private struct ProjectCreateView: View {
  @Binding var name: String
  let isCreating: Bool
  let onCancel: () -> Void
  let onConfirm: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Local Project 만들기")
        .font(.title2.bold())
      TextField("프로젝트 이름", text: $name)
        .textFieldStyle(.roundedBorder)
        .accessibilityIdentifier(AccessibilityID.ProjectSidebar.createNameField)
      HStack {
        Spacer()
        Button("취소", action: onCancel)
        Button("만들기", action: onConfirm)
          .keyboardShortcut(.defaultAction)
          .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
          .accessibilityIdentifier(AccessibilityID.ProjectSidebar.createConfirmButton)
      }
    }
    .padding(24)
    .frame(width: 360)
  }
}
