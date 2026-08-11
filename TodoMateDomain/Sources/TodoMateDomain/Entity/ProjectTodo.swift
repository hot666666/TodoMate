import Foundation

public struct TodoID: Hashable, Codable, Sendable, RawRepresentable, CustomStringConvertible {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public var description: String {
    rawValue
  }
}

public struct ProjectTodoTitle: Hashable, Codable, Sendable {
  public enum ValidationError: Error, Equatable, Sendable {
    case empty
    case tooLong(maximum: Int)
  }

  public static let maximumLength = 200
  public let value: String

  public init(_ value: String) throws {
    let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !normalized.isEmpty else { throw ValidationError.empty }
    guard normalized.count <= Self.maximumLength else {
      throw ValidationError.tooLong(maximum: Self.maximumLength)
    }
    self.value = normalized
  }
}

public struct ProjectTodo: Equatable, Codable, Identifiable, Sendable {
  public let id: TodoID
  public let projectID: ProjectID
  public let authorID: ContentAuthorID
  public var title: ProjectTodoTitle
  public var status: TodoStatus
  public let createdAt: Date
  public var updatedAt: Date

  public init(
    id: TodoID,
    projectID: ProjectID,
    authorID: ContentAuthorID,
    title: ProjectTodoTitle,
    status: TodoStatus = .todo,
    createdAt: Date,
    updatedAt: Date,
  ) {
    self.id = id
    self.projectID = projectID
    self.authorID = authorID
    self.title = title
    self.status = status
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}
