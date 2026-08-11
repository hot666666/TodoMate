import Foundation
import TodoMateDomain

public struct CreateTodoCommand: Equatable, Sendable {
  public let projectID: ProjectID
  public let title: String

  public init(projectID: ProjectID, title: String) {
    self.projectID = projectID
    self.title = title
  }
}

public protocol ProjectTodoPersistence: Sendable {
  func observe(projectID: ProjectID) -> AsyncStream<[ProjectTodo]>
  func create(_ todo: ProjectTodo) async throws
}

public struct TodoClient: Sendable {
  public var observe: @Sendable (ProjectID) -> AsyncStream<[ProjectTodo]>
  public var create: @Sendable (CreateTodoCommand) async throws -> TodoID

  public init(
    observe: @escaping @Sendable (ProjectID) -> AsyncStream<[ProjectTodo]>,
    create: @escaping @Sendable (CreateTodoCommand) async throws -> TodoID,
  ) {
    self.observe = observe
    self.create = create
  }
}

public extension TodoClient {
  static func live(
    persistence: any ProjectTodoPersistence,
    generateID: @escaping @Sendable () -> TodoID = { TodoID(rawValue: UUID().uuidString) },
    currentAuthorID: ContentAuthorID = ContentAuthorID(rawValue: User.local.id),
    now: @escaping @Sendable () -> Date = Date.init,
  ) -> Self {
    Self(
      observe: { persistence.observe(projectID: $0) },
      create: { command in
        let instant = now()
        let todo = try ProjectTodo(
          id: generateID(),
          projectID: command.projectID,
          authorID: currentAuthorID,
          title: ProjectTodoTitle(command.title),
          createdAt: instant,
          updatedAt: instant,
        )
        try await persistence.create(todo)
        return todo.id
      },
    )
  }
}
