import ComposableArchitecture
import Testing
import TodoMateApplication
import TodoMateDomain
@testable import TodoMatePresentation

@MainActor
@Suite("ProjectSidebarFeature")
struct ProjectSidebarFeatureTests {
  private struct TestFailure: Error {}

  @Test("Create action calls typed Project client and closes presentation")
  func createProject() async {
    let expectedID = ProjectID(rawValue: "project-1")
    let store = TestStore(initialState: ProjectSidebarFeature.State()) {
      ProjectSidebarFeature()
    } withDependencies: {
      $0.projectClient = ProjectClient(
        snapshots: { AsyncStream { $0.finish() } },
        createLocal: { command in
          #expect(command.name == "Daily")
          return expectedID
        },
        select: { _ in },
      )
    }

    await store.send(.view(.createButtonTapped)) {
      $0.isCreatePresented = true
    }
    await store.send(.view(.createNameChanged("Daily"))) {
      $0.newProjectName = "Daily"
    }
    await store.send(.view(.createConfirmed)) {
      $0.operation = .creating
    }
    await store.receive(.internal(.createFinished(expectedID))) {
      $0.isCreatePresented = false
      $0.newProjectName = ""
      $0.operation = .idle
    }
  }

  @Test("Selection ignores competing mutations until the in-flight selection finishes")
  func selectionIsSerialized() async {
    let firstID = ProjectID(rawValue: "first")
    let secondID = ProjectID(rawValue: "second")
    var state = ProjectSidebarFeature.State()
    state.newProjectName = "Daily"
    state.operation = .selecting(firstID)
    let store = TestStore(initialState: state) {
      ProjectSidebarFeature()
    } withDependencies: {
      $0.projectClient = ProjectClient(
        snapshots: { AsyncStream { $0.finish() } },
        createLocal: { _ in
          Issue.record("Busy selection must not start a create effect")
          return secondID
        },
        select: { _ in
          Issue.record("Busy selection must not start another selection effect")
        },
      )
    }

    await store.send(.view(.projectSelected(secondID)))
    await store.send(.view(.createButtonTapped))
    await store.send(.view(.createConfirmed))
  }

  @Test("Creating cannot be cancelled or replaced by another mutation")
  func creatingCannotBeCancelled() async {
    let projectID = ProjectID(rawValue: "project")
    var state = ProjectSidebarFeature.State()
    state.isCreatePresented = true
    state.newProjectName = "Daily"
    state.operation = .creating
    let store = TestStore(initialState: state) {
      ProjectSidebarFeature()
    } withDependencies: {
      $0.projectClient = ProjectClient(
        snapshots: { AsyncStream { $0.finish() } },
        createLocal: { _ in
          Issue.record("Busy create must not start another create effect")
          return projectID
        },
        select: { _ in
          Issue.record("Busy create must not start a selection effect")
        },
      )
    }

    await store.send(.view(.createCancelled))
    await store.send(.view(.createConfirmed))
    await store.send(.view(.projectSelected(projectID)))
  }

  @Test("Overlong Project name stays visible with validation feedback")
  func overlongProjectName() async {
    let projectID = ProjectID(rawValue: "project")
    let overlongName = String(repeating: "A", count: ProjectName.maximumLength + 1)
    let store = TestStore(initialState: ProjectSidebarFeature.State()) {
      ProjectSidebarFeature()
    } withDependencies: {
      $0.projectClient = ProjectClient(
        snapshots: { AsyncStream { $0.finish() } },
        createLocal: { _ in
          Issue.record("Invalid Project name must not reach the Application client")
          return projectID
        },
        select: { _ in },
      )
    }

    await store.send(.view(.createButtonTapped)) {
      $0.isCreatePresented = true
    }
    await store.send(.view(.createNameChanged(overlongName))) {
      $0.newProjectName = overlongName
    }
    await store.send(.view(.createConfirmed)) {
      $0.failureMessage = "프로젝트 이름은 \(ProjectName.maximumLength)자 이하로 입력해 주세요."
    }
  }

  @Test("Create failure returns to an actionable state with visible feedback")
  func createFailure() async {
    let store = TestStore(initialState: ProjectSidebarFeature.State()) {
      ProjectSidebarFeature()
    } withDependencies: {
      $0.projectClient = ProjectClient(
        snapshots: { AsyncStream { $0.finish() } },
        createLocal: { _ in throw TestFailure() },
        select: { _ in },
      )
    }

    await store.send(.view(.createButtonTapped)) {
      $0.isCreatePresented = true
    }
    await store.send(.view(.createNameChanged("Daily"))) {
      $0.newProjectName = "Daily"
    }
    await store.send(.view(.createConfirmed)) {
      $0.operation = .creating
    }
    await store.receive(.internal(.createFinished(nil))) {
      $0.operation = .idle
      $0.failureMessage = "프로젝트를 만들지 못했습니다. 다시 시도해 주세요."
    }
  }
}
