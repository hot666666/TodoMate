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
      failureMessage: store.failureMessage,
      isBusy: store.operation != .idle,
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
        canConfirm: store.canConfirmCreate,
        errorMessage: store.createValidationMessage ?? store.failureMessage,
        onCancel: { store.send(.view(.createCancelled)) },
        onConfirm: { store.send(.view(.createConfirmed)) },
      )
      .interactiveDismissDisabled(store.operation == .creating)
    }
  }
}

private struct ProjectSidebarView: View {
  let projects: [Project]
  let selectedProjectID: ProjectID?
  let failureMessage: String?
  let isBusy: Bool
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
          .disabled(isBusy)
          .listRowBackground(
            selectedProjectID == project.id ? Color.accentColor.opacity(0.18) : Color.clear,
          )
          .accessibilityIdentifier(AccessibilityID.ProjectSidebar.row(project.id.rawValue))
        }
      }
    }
    .safeAreaInset(edge: .bottom) {
      VStack(alignment: .leading, spacing: 8) {
        if let failureMessage {
          Text(failureMessage)
            .font(.caption)
            .foregroundStyle(.red)
        }
        Button(action: onCreate) {
          Label("새 프로젝트", systemImage: "plus")
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
        .accessibilityIdentifier(AccessibilityID.ProjectSidebar.createButton)
      }
      .padding()
    }
  }
}

private struct ProjectCreateView: View {
  @Binding var name: String
  let isCreating: Bool
  let canConfirm: Bool
  let errorMessage: String?
  let onCancel: () -> Void
  let onConfirm: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Local Project 만들기")
        .font(.title2.bold())
      TextField("프로젝트 이름", text: $name)
        .textFieldStyle(.roundedBorder)
        .accessibilityIdentifier(AccessibilityID.ProjectSidebar.createNameField)
      if let errorMessage {
        Text(errorMessage)
          .font(.caption)
          .foregroundStyle(.red)
          .accessibilityIdentifier(AccessibilityID.ProjectSidebar.createError)
      }
      HStack {
        Spacer()
        Button("취소", action: onCancel)
          .disabled(isCreating)
        Button("만들기", action: onConfirm)
          .keyboardShortcut(.defaultAction)
          .disabled(!canConfirm)
          .accessibilityIdentifier(AccessibilityID.ProjectSidebar.createConfirmButton)
      }
    }
    .padding(24)
    .frame(width: 360)
  }
}
