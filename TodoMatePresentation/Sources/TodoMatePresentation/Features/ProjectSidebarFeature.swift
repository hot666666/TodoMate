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
    public var failureMessage: String?

    public var canConfirmCreate: Bool {
      operation == .idle && (try? ProjectName(newProjectName)) != nil
    }

    public var createValidationMessage: String? {
      let normalizedName = newProjectName.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !normalizedName.isEmpty, normalizedName.count > ProjectName.maximumLength else {
        return nil
      }
      return "프로젝트 이름은 \(ProjectName.maximumLength)자 이하로 입력해 주세요."
    }

    // swiftlint:disable:next nesting
    public enum Operation: Equatable, Sendable {
      case idle
      case creating
      case selecting(ProjectID)
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
        guard state.operation == .idle else { return .none }
        state.newProjectName = ""
        state.isCreatePresented = true
        state.failureMessage = nil
        return .none

      case let .view(.createNameChanged(name)):
        state.newProjectName = name
        state.failureMessage = nil
        return .none

      case .view(.createCancelled):
        guard state.operation != .creating else { return .none }
        state.isCreatePresented = false
        state.newProjectName = ""
        state.operation = .idle
        state.failureMessage = nil
        return .none

      case .view(.createConfirmed):
        guard state.canConfirmCreate else {
          if state.createValidationMessage != nil {
            state.failureMessage = state.createValidationMessage
          }
          return .none
        }
        let name = state.newProjectName
        state.operation = .creating
        state.failureMessage = nil
        return .run { send in
          do {
            let projectID = try await projectClient.createLocal(.init(name: name))
            await send(.internal(.createFinished(projectID)))
          } catch {
            await send(.internal(.createFinished(nil)))
          }
        }

      case let .view(.projectSelected(projectID)):
        guard state.operation == .idle else { return .none }
        state.operation = .selecting(projectID)
        state.failureMessage = nil
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
        state.failureMessage = nil
        return .none

      case .internal(.createFinished(nil)):
        state.operation = .idle
        state.failureMessage = "프로젝트를 만들지 못했습니다. 다시 시도해 주세요."
        return .none

      case let .internal(.selectionFinished(projectID, .success)):
        state.selectedProjectID = projectID
        state.operation = .idle
        state.failureMessage = nil
        return .none

      case .internal(.selectionFinished(_, .failure)):
        state.operation = .idle
        state.failureMessage = "프로젝트를 선택하지 못했습니다. 다시 시도해 주세요."
        return .none
      }
    }
  }
}
