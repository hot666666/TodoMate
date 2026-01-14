//
//  User.swift
//  Todo
//
//  Created by hs on 5/24/25.
//

import Foundation

public struct User: Identifiable, Codable, Equatable, Sendable {
  public let id: String
  /// DocumentID
  public var displayName: String
  public var groupId: String
  /// GroupID
  public let createdAt: Date
  public var updatedAt: Date

  public init(
    id: String,
    displayName: String,
    groupId: String,
    createdAt: Date,
    updatedAt: Date,
  ) {
    self.id = id
    self.displayName = displayName
    self.groupId = groupId
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  public init(
    id: String = UUID().uuidString,
    displayName: String = "Unknown",
    groupId: String = "",
  ) {
    let now: Date = .now
    self.init(
      id: id,
      displayName: displayName,
      groupId: groupId,
      createdAt: now,
      updatedAt: now,
    )
  }
}

public extension User {
  static let dummy = User(id: "", groupId: "")

  static let stub = User(
    id: EntityConstant.User.stubId,
    displayName: EntityConstant.User.stubDisplayName,
    groupId: EntityConstant.UserGroup.stubId,
    createdAt: .now,
    updatedAt: .now,
  )

  static let stubs = [
    User(
      id: EntityConstant.User.stubId, displayName: "hs", groupId: EntityConstant.UserGroup.stubId,
    ),
    User(displayName: "jy", groupId: EntityConstant.UserGroup.stubId),
  ]
}

// MARK: - Array Extension

extension [User] {
  func placingFirst(_ user: User) -> [User] {
    [user] + filter { $0.id != user.id }
  }
}
