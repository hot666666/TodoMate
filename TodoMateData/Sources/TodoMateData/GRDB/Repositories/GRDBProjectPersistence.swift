import Common
import Foundation
import GRDB
import TodoMateApplication
import TodoMateDomain

public final class GRDBProjectPersistence: ProjectPersistence, Sendable {
  public enum Error: Swift.Error, Equatable, Sendable {
    case missingProject(ProjectID)
    case invalidLifecycle(String)
  }

  private let database: GRDBDatabase

  public init(database: GRDBDatabase) {
    self.database = database
  }

  public func snapshots() -> AsyncStream<ProjectWorkspaceSnapshot> {
    database.observe(
      region: .project,
      fetch: Self.fetchSnapshot,
      transform: { $0 },
      onError: { error in
        Log.error("Project workspace observation failed: \(error)", category: .data)
      }
    )
  }

  public func create(
    _ project: Project,
    ownerMembership: Membership,
    selecting: Bool
  ) async throws {
    try await database.writer.write { databaseConnection in
      try ProjectRecord(project).insert(databaseConnection)
      try MembershipRecord(ownerMembership).insert(databaseConnection)
      if selecting {
        try ProjectSelectionRecord(
          key: ProjectSelectionRecord.currentKey,
          projectId: project.id.rawValue
        ).save(databaseConnection)
      }
    }
  }

  public func select(_ projectID: ProjectID) async throws {
    try await database.writer.write { databaseConnection in
      guard try ProjectRecord.fetchOne(databaseConnection, key: projectID.rawValue) != nil else {
        throw Error.missingProject(projectID)
      }
      try ProjectSelectionRecord(
        key: ProjectSelectionRecord.currentKey,
        projectId: projectID.rawValue
      ).save(databaseConnection)
    }
  }

  private static func fetchSnapshot(
    _ databaseConnection: Database
  ) throws -> ProjectWorkspaceSnapshot {
    let projects = try ProjectRecord
      .order(ProjectRecord.Columns.createdAt, ProjectRecord.Columns.id)
      .fetchAll(databaseConnection)
      .map { try $0.domainValue() }
    let storedSelection = try ProjectSelectionRecord.fetchOne(
      databaseConnection,
      key: ProjectSelectionRecord.currentKey
    )
    let selectedProjectID = storedSelection
      .map { ProjectID(rawValue: $0.projectId) }
      .flatMap { selected in projects.contains(where: { $0.id == selected }) ? selected : nil }

    return ProjectWorkspaceSnapshot(
      projects: projects,
      selectedProjectID: selectedProjectID
    )
  }
}

public extension ProjectClient {
  static func grdb(
    database: GRDBDatabase,
    generateID: @escaping @Sendable () -> ProjectID = { ProjectID(rawValue: UUID().uuidString) },
    generateMembershipID: @escaping @Sendable () -> MembershipID = {
      MembershipID(rawValue: UUID().uuidString)
    },
    currentAuthorID: ContentAuthorID = ContentAuthorID(rawValue: User.local.id),
    now: @escaping @Sendable () -> Date = Date.init
  ) -> Self {
    .live(
      persistence: GRDBProjectPersistence(database: database),
      generateID: generateID,
      generateMembershipID: generateMembershipID,
      currentAuthorID: currentAuthorID,
      now: now
    )
  }
}
