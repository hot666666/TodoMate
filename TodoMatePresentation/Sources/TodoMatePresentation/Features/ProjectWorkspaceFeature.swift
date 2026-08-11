import ComposableArchitecture
import TodoMateDomain

@Reducer
public struct ProjectWorkspaceFeature: Sendable {
  @ObservableState
  public struct State: Equatable, Sendable {
    public var project: Project
    public var selectedSection: Section

    // swiftlint:disable:next nesting
    public enum Section: String, CaseIterable, Equatable, Sendable {
      case todo
      case memo
      case chat
    }

    public init(project: Project, selectedSection: Section = .todo) {
      self.project = project
      self.selectedSection = selectedSection
    }
  }

  public enum Action: Equatable, Sendable {
    case view(ViewAction)

    // swiftlint:disable:next nesting
    public enum ViewAction: Equatable, Sendable {
      case sectionSelected(State.Section)
    }
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .view(.sectionSelected(section)):
        state.selectedSection = section
        return .none
      }
    }
  }
}
