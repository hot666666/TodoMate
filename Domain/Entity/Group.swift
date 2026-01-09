//
//  Group.swift
//  TodoMate
//
//  Created by agent on 1/9/26.
//

import Foundation

struct UserGroup: Identifiable, Codable, Equatable {
  let id: String
  var name: String
  var memberIds: [String]
  let createdAt: Date
  var updatedAt: Date

  init(
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

extension UserGroup {
  static let stub = UserGroup(
    id: EntityConstant.UserGroup.stubId,
    name: "Test Group",
    memberIds: [EntityConstant.User.stubId],
  )
}
