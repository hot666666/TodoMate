import ComposableArchitecture
import TodoMateApplication
import TodoMateDomain

@Reducer
public struct AppFeature: Sendable {
  @ObservableState
  public struct State: Equatable, Sendable {
    public var launchPhase: LaunchPhase = .loading
    public var sidebar = ProjectSidebarFeature.State()
    public var workspace: ProjectWorkspaceFeature.State?

    // swiftlint:disable:next nesting
    public enum LaunchPhase: Equatable, Sendable {
      case loading
      case ready
    }

    public init() {}
  }

  public enum Action: Equatable, Sendable {
    case view(ViewAction)
    case `internal`(InternalAction)
    case sidebar(ProjectSidebarFeature.Action)
    case workspace(ProjectWorkspaceFeature.Action)

    // swiftlint:disable:next nesting
    public enum ViewAction: Equatable, Sendable {
      case task
    }

    // swiftlint:disable:next nesting
    public enum InternalAction: Equatable, Sendable {
      case snapshotUpdated(ProjectWorkspaceSnapshot)
    }
  }

  private enum CancelID {
    case projectSnapshots
  }

  @Dependency(\.projectClient) private var projectClient

  public init() {}

  public var body: some ReducerOf<Self> {
    Scope(state: \.sidebar, action: \.sidebar) {
      ProjectSidebarFeature()
    }
    Reduce { state, action in
      switch action {
      case .view(.task):
        return .run { send in
          for await snapshot in projectClient.snapshots() {
            await send(.internal(.snapshotUpdated(snapshot)))
          }
        }
        .cancellable(id: CancelID.projectSnapshots, cancelInFlight: true)

      case let .internal(.snapshotUpdated(snapshot)):
        state.launchPhase = .ready
        state.sidebar.projects = snapshot.projects
        state.sidebar.selectedProjectID = snapshot.selectedProjectID

        guard
          let selectedProjectID = snapshot.selectedProjectID,
          let project = snapshot.projects.first(where: { $0.id == selectedProjectID })
        else {
          state.workspace = nil
          return .none
        }

        if state.workspace?.project.id == project.id {
          state.workspace?.project = project
        } else if state.workspace != nil {
          return .send(.workspace(.internal(.projectChanged(project))))
        } else {
          state.workspace = ProjectWorkspaceFeature.State(project: project, selectedSection: .todo)
        }
        return .none

      case .sidebar, .workspace:
        return .none
      }
    }
    .ifLet(\.workspace, action: \.workspace) {
      ProjectWorkspaceFeature()
    }
  }
}
