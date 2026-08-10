import ComposableArchitecture
import Foundation
import Testing
import TodoMateApplication
import TodoMateDomain
@testable import TodoMatePresentation

@MainActor
@Suite("AppFeature")
struct AppFeatureTests {
  @Test("Launch restores selected Project and opens Todo section")
  func launchRestoration() async throws {
    let project = try Project(
      id: .init(rawValue: "project-1"),
      name: ProjectName("Daily"),
      lifecycle: .local,
      createdAt: Date(timeIntervalSince1970: 1),
      updatedAt: Date(timeIntervalSince1970: 1),
    )
    let snapshot = ProjectWorkspaceSnapshot(
      projects: [project],
      selectedProjectID: project.id,
    )
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    } withDependencies: {
      $0.projectClient = ProjectClient(
        snapshots: { AsyncStream { continuation in
          continuation.yield(snapshot)
          continuation.finish()
        } },
        createLocal: { _ in project.id },
        select: { _ in },
      )
    }

    await store.send(.view(.task))
    await store.receive(.internal(.snapshotUpdated(snapshot))) {
      $0.launchPhase = .ready
      $0.sidebar.projects = [project]
      $0.sidebar.selectedProjectID = project.id
      $0.workspace = .init(project: project, selectedSection: .todo)
    }
  }

  @Test("Project switch resets Workspace to Todo section")
  func projectSwitch() async {
    let first = makeProject(id: "first", name: "First")
    let second = makeProject(id: "second", name: "Second")
    var state = AppFeature.State()
    state.launchPhase = .ready
    state.sidebar = .init(projects: [first, second], selectedProjectID: first.id)
    state.workspace = .init(project: first, selectedSection: .chat)
    let store = TestStore(initialState: state) { AppFeature() }

    await store.send(.internal(.snapshotUpdated(.init(
      projects: [first, second],
      selectedProjectID: second.id,
    )))) {
      $0.sidebar.selectedProjectID = second.id
      $0.workspace = .init(project: second, selectedSection: .todo)
    }
  }

  private func makeProject(id: String, name: String) -> Project {
    Project(
      id: .init(rawValue: id),
      name: try! ProjectName(name),
      lifecycle: .local,
      createdAt: Date(timeIntervalSince1970: 1),
      updatedAt: Date(timeIntervalSince1970: 1),
    )
  }
}
