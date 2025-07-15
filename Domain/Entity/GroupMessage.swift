//
//  GroupMessage.swift
//  Todo
//
//  Created by hs on 6/9/25.
//

import Foundation

struct GroupMessage: Identifiable, Codable {
  let id: String
  var content: String
  let groupId: String
  let owner: String
  let createdAt: Date
  var updatedAt: Date

  init(content: String, groupId: String, owner: String) {
    let now = Date()
    id = UUID().uuidString
    self.content = content
    self.groupId = groupId
    self.owner = owner
    createdAt = now
    updatedAt = now
  }

  func withUpdatedContent(_ content: String) -> GroupMessage? {
    let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    var updated = self
    updated.content = trimmed
    updated.updatedAt = Date()
    return updated
  }
}

extension GroupMessage {
  static let stub = GroupMessage(content: "안녕하세요1", groupId: User.stub.groupId, owner: User.stub.id)
}
