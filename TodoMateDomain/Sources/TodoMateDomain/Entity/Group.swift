//
//  Group.swift
//  TodoMate
//
//  Created by agent on 1/9/26.
//

import Foundation

public struct UserGroup: Identifiable, Codable, Equatable, Sendable {
  public let id: String
  public var name: String
  public var memberIds: [String]
  public let createdAt: Date
  public var updatedAt: Date

  public init(
    id: String = UUID().uuidString,
    name: String,
    memberIds: [String] = [],
    createdAt: Date = .now,
    updatedAt: Date = .now,
  ) {
    self.id = id
    self.name = name
    self.memberIds = memberIds
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

public extension UserGroup {
  static let stub = UserGroup(
    id: EntityConstant.UserGroup.stubId,
    name: "Test Group",
    memberIds: [EntityConstant.User.stubId],
  )
}
