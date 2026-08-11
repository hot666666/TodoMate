import Foundation

public struct ProjectID: Hashable, Codable, Sendable, RawRepresentable, CustomStringConvertible {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public var description: String {
    rawValue
  }
}

public struct ProjectName: Hashable, Codable, Sendable {
  public enum ValidationError: Error, Equatable, Sendable {
    case empty
    case tooLong(maximum: Int)
  }

  public static let maximumLength = 80
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

public struct Project: Equatable, Codable, Identifiable, Sendable {
  public enum Lifecycle: String, Codable, Sendable {
    case local
  }

  public let id: ProjectID
  public var name: ProjectName
  public let lifecycle: Lifecycle
  public let createdAt: Date
  public var updatedAt: Date

  public init(
    id: ProjectID,
    name: ProjectName,
    lifecycle: Lifecycle,
    createdAt: Date,
    updatedAt: Date,
  ) {
    self.id = id
    self.name = name
    self.lifecycle = lifecycle
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}
