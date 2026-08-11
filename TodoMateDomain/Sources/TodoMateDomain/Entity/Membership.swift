import Foundation

public struct ContentAuthorID: Hashable, Codable, Sendable, RawRepresentable {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

public struct MembershipID: Hashable, Codable, Sendable, RawRepresentable {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

public struct Membership: Equatable, Codable, Identifiable, Sendable {
  public enum Role: String, Codable, Sendable {
    case owner
    case member
  }

  public let id: MembershipID
  public let projectID: ProjectID
  public let authorID: ContentAuthorID
  public let role: Role
  public let createdAt: Date

  public init(
    id: MembershipID,
    projectID: ProjectID,
    authorID: ContentAuthorID,
    role: Role,
    createdAt: Date,
  ) {
    self.id = id
    self.projectID = projectID
    self.authorID = authorID
    self.role = role
    self.createdAt = createdAt
  }
}
