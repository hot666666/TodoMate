//
//  User.swift
//  Todo
//
//  Created by hs on 5/24/25.
//

import Foundation

struct User: Codable, Identifiable {
  let id: String /// DocumentID
  var displayName: String
  var groupId: String /// GroupID
  let createdAt: Date
  var updatedAt: Date

  init(
    id: String,
    displayName: String,
    groupId: String,
    createdAt: Date,
    updatedAt: Date
  ) {
    self.id = id
    self.displayName = displayName
    self.groupId = groupId
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  init(
    id: String = UUID().uuidString,
    displayName: String = "Unknown",
    groupId: String = UUID().uuidString
  ) {
    let now: Date = .now
    self.init(
      id: id,
      displayName: displayName,
      groupId: groupId,
      createdAt: now,
      updatedAt: now
    )
  }
}

extension User {
  static let dummy = User(id: "", groupId: "")

  static let stub = User(
    id: EntityConstant.User.stubId,
    displayName: EntityConstant.User.stubDisplayName,
    groupId: EntityConstant.UserGroup.stubId,
    createdAt: .now,
    updatedAt: .now
  )

  static let stubs = [
    User(id: EntityConstant.User.stubId, displayName: "hs", groupId: EntityConstant.UserGroup.stubId),
    User(displayName: "jy", groupId: EntityConstant.UserGroup.stubId),
  ]
}
