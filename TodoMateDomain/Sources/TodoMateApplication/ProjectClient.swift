import Foundation
import TodoMateDomain

public struct ProjectWorkspaceSnapshot: Equatable, Sendable {
  public var projects: [Project]
  public var selectedProjectID: ProjectID?

  public init(projects: [Project], selectedProjectID: ProjectID?) {
    self.projects = projects
    self.selectedProjectID = selectedProjectID
  }
}

public struct CreateLocalProjectCommand: Equatable, Sendable {
  public let name: String

  public init(name: String) {
    self.name = name
  }
}

public protocol ProjectPersistence: Sendable {
  func snapshots() -> AsyncStream<ProjectWorkspaceSnapshot>
  func create(_ project: Project, ownerMembership: Membership, selecting: Bool) async throws
  func select(_ projectID: ProjectID) async throws
}

public struct ProjectClient: Sendable {
  public var snapshots: @Sendable () -> AsyncStream<ProjectWorkspaceSnapshot>
  public var createLocal: @Sendable (CreateLocalProjectCommand) async throws -> ProjectID
  public var select: @Sendable (ProjectID) async throws -> Void

  public init(
    snapshots: @escaping @Sendable () -> AsyncStream<ProjectWorkspaceSnapshot>,
    createLocal: @escaping @Sendable (CreateLocalProjectCommand) async throws -> ProjectID,
    select: @escaping @Sendable (ProjectID) async throws -> Void,
  ) {
    self.snapshots = snapshots
    self.createLocal = createLocal
    self.select = select
  }
}

public extension ProjectClient {
  static func live(
    persistence: any ProjectPersistence,
    generateID: @escaping @Sendable () -> ProjectID = { ProjectID(rawValue: UUID().uuidString) },
    generateMembershipID: @escaping @Sendable () -> MembershipID = {
      MembershipID(rawValue: UUID().uuidString)
    },
    currentAuthorID: ContentAuthorID = ContentAuthorID(rawValue: User.local.id),
    now: @escaping @Sendable () -> Date = Date.init,
  ) -> Self {
    Self(
      snapshots: { persistence.snapshots() },
      createLocal: { command in
        let instant = now()
        let project = try Project(
          id: generateID(),
          name: ProjectName(command.name),
          lifecycle: .local,
          createdAt: instant,
          updatedAt: instant,
        )
        let ownerMembership = Membership(
          id: generateMembershipID(),
          projectID: project.id,
          authorID: currentAuthorID,
          role: .owner,
          createdAt: instant,
        )
        try await persistence.create(project, ownerMembership: ownerMembership, selecting: true)
        return project.id
      },
      select: { projectID in
        try await persistence.select(projectID)
      },
    )
  }
}
