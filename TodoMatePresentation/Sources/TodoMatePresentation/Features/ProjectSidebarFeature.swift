import ComposableArchitecture
import TodoMateApplication
import TodoMateDomain

@Reducer
public struct ProjectSidebarFeature: Sendable {
  @ObservableState
  public struct State: Equatable, Sendable {
    public var projects: [Project]
    public var selectedProjectID: ProjectID?
    public var isCreatePresented = false
    public var newProjectName = ""
    public var operation: Operation = .idle

    // swiftlint:disable:next nesting
    public enum Operation: Equatable, Sendable {
      case idle
      case creating
      case selecting(ProjectID)
      case failed
    }

    public init(projects: [Project] = [], selectedProjectID: ProjectID? = nil) {
      self.projects = projects
      self.selectedProjectID = selectedProjectID
    }
  }

  public enum Action: Equatable, Sendable {
    case view(ViewAction)
    case `internal`(InternalAction)

    // swiftlint:disable:next nesting
    public enum ViewAction: Equatable, Sendable {
      case createButtonTapped
      case createNameChanged(String)
      case createConfirmed
      case createCancelled
      case projectSelected(ProjectID)
    }

    // swiftlint:disable:next nesting
    public enum InternalAction: Equatable, Sendable {
      case createFinished(ProjectID?)
      case selectionFinished(ProjectID, SelectionResult)
    }

    // swiftlint:disable:next nesting
    public enum SelectionResult: Equatable, Sendable {
      case success
      case failure
    }
  }

  @Dependency(\.projectClient) private var projectClient

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .view(.createButtonTapped):
        state.newProjectName = ""
        state.isCreatePresented = true
        state.operation = .idle
        return .none

      case let .view(.createNameChanged(name)):
        state.newProjectName = name
        return .none

      case .view(.createCancelled):
        state.isCreatePresented = false
        state.newProjectName = ""
        state.operation = .idle
        return .none

      case .view(.createConfirmed):
        guard state.operation != .creating else { return .none }
        let name = state.newProjectName
        state.operation = .creating
        return .run { send in
          do {
            let projectID = try await projectClient.createLocal(.init(name: name))
            await send(.internal(.createFinished(projectID)))
          } catch {
            await send(.internal(.createFinished(nil)))
          }
        }

      case let .view(.projectSelected(projectID)):
        guard state.operation != .selecting(projectID) else { return .none }
        state.operation = .selecting(projectID)
        return .run { send in
          do {
            try await projectClient.select(projectID)
            await send(.internal(.selectionFinished(projectID, .success)))
          } catch {
            await send(.internal(.selectionFinished(projectID, .failure)))
          }
        }

      case .internal(.createFinished(.some)):
        state.isCreatePresented = false
        state.newProjectName = ""
        state.operation = .idle
        return .none

      case .internal(.createFinished(nil)):
        state.operation = .failed
        return .none

      case let .internal(.selectionFinished(projectID, .success)):
        state.selectedProjectID = projectID
        state.operation = .idle
        return .none

      case .internal(.selectionFinished(_, .failure)):
        state.operation = .failed
        return .none
      }
    }
  }
}
