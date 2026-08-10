import ComposableArchitecture
import Testing
import TodoMateApplication
import TodoMateDomain
@testable import TodoMatePresentation

@MainActor
@Suite("ProjectSidebarFeature")
struct ProjectSidebarFeatureTests {
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
}
