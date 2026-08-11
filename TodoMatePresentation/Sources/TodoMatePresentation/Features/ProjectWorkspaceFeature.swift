import ComposableArchitecture
import Foundation
import TodoMateApplication
import TodoMateDomain

@Reducer
public struct ProjectWorkspaceFeature: Sendable {
  @ObservableState
  public struct State: Equatable, Sendable {
    public var project: Project
    public var selectedSection: Section
    public var todos: [ProjectTodo]
    public var todoDraft: String
    public var isCreatingTodo: Bool
    public var todoError: String?

    public var canCreateTodo: Bool {
      let normalized = todoDraft.trimmingCharacters(in: .whitespacesAndNewlines)
      return !isCreatingTodo
        && !normalized.isEmpty
        && normalized.count <= ProjectTodoTitle.maximumLength
    }

    // swiftlint:disable:next nesting
    public enum Section: String, CaseIterable, Equatable, Sendable {
      case todo
      case memo
      case chat
    }

    public init(
      project: Project,
      selectedSection: Section = .todo,
      todos: [ProjectTodo] = [],
      todoDraft: String = "",
      isCreatingTodo: Bool = false,
      todoError: String? = nil,
    ) {
      self.project = project
      self.selectedSection = selectedSection
      self.todos = todos
      self.todoDraft = todoDraft
      self.isCreatingTodo = isCreatingTodo
      self.todoError = todoError
    }
  }

  public enum Action: Equatable, Sendable {
    case view(ViewAction)
    case `internal`(InternalAction)

    // swiftlint:disable:next nesting
    public enum ViewAction: Equatable, Sendable {
      case sectionSelected(State.Section)
      case task
      case todoDraftChanged(String)
      case createTodoTapped
    }

    // swiftlint:disable:next nesting
    public enum InternalAction: Equatable, Sendable {
      case projectChanged(Project)
      case todosUpdated([ProjectTodo])
      case todoCreated(TodoID)
      case todoCreationFailed
    }
  }

  enum CancelID {
    case todoCreation
    case todoObservation
  }

  @Dependency(\.todoClient) private var todoClient

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .view(.sectionSelected(section)):
        state.selectedSection = section
        return .none

      case .view(.task):
        let projectID = state.project.id
        return .run { send in
          for await todos in todoClient.observe(projectID) {
            await send(.internal(.todosUpdated(todos)))
          }
        }
        .cancellable(id: CancelID.todoObservation, cancelInFlight: true)

      case let .view(.todoDraftChanged(value)):
        state.todoDraft = value
        state.todoError = nil
        return .none

      case .view(.createTodoTapped):
        guard state.canCreateTodo else { return .none }
        let command = CreateTodoCommand(projectID: state.project.id, title: state.todoDraft)
        state.isCreatingTodo = true
        state.todoError = nil
        return .run { send in
          do {
            try await send(.internal(.todoCreated(todoClient.create(command))))
          } catch {
            guard !Task.isCancelled else { return }
            await send(.internal(.todoCreationFailed))
          }
        }
        .cancellable(id: CancelID.todoCreation)

      case let .internal(.todosUpdated(todos)):
        state.todos = todos
        return .none

      case let .internal(.projectChanged(project)):
        state.project = project
        state.selectedSection = .todo
        state.todos = []
        state.todoDraft = ""
        state.isCreatingTodo = false
        state.todoError = nil
        return .merge(
          .cancel(id: CancelID.todoCreation),
          .cancel(id: CancelID.todoObservation),
        )

      case .internal(.todoCreated):
        state.isCreatingTodo = false
        state.todoDraft = ""
        return .none

      case .internal(.todoCreationFailed):
        state.isCreatingTodo = false
        state.todoError = "Todo를 만들지 못했습니다. 다시 시도해 주세요."
        return .none
      }
    }
  }
}
