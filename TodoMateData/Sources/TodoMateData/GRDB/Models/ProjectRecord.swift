import Foundation
import GRDB
import TodoMateDomain

struct ProjectRecord: Codable, Equatable, FetchableRecord, PersistableRecord, Sendable {
  static let databaseTableName = "project"

  enum Columns {
    static let id = Column("id")
    static let createdAt = Column("createdAt")
  }

  let id: String
  let name: String
  let lifecycle: String
  let createdAt: Date
  let updatedAt: Date

  init(_ project: Project) {
    id = project.id.rawValue
    name = project.name.value
    lifecycle = project.lifecycle.rawValue
    createdAt = project.createdAt
    updatedAt = project.updatedAt
  }

  func domainValue() throws -> Project {
    guard let lifecycle = Project.Lifecycle(rawValue: lifecycle) else {
      throw GRDBProjectPersistence.Error.invalidLifecycle(lifecycle)
    }
    return try Project(
      id: ProjectID(rawValue: id),
      name: ProjectName(name),
      lifecycle: lifecycle,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }
}

struct ProjectSelectionRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
  static let databaseTableName = "projectSelection"
  static let currentKey = "current"

  let key: String
  let projectId: String
}

struct MembershipRecord: Codable, Equatable, FetchableRecord, PersistableRecord, Sendable {
  static let databaseTableName = "membership"

  let id: String
  let projectId: String
  let authorId: String
  let role: String
  let createdAt: Date

  init(_ membership: Membership) {
    id = membership.id.rawValue
    projectId = membership.projectID.rawValue
    authorId = membership.authorID.rawValue
    role = membership.role.rawValue
    createdAt = membership.createdAt
  }
}
