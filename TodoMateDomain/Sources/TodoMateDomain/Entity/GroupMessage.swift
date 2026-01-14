//
//  GroupMessage.swift
//  Todo
//
//  Created by hs on 6/9/25.
//

import Foundation

public struct GroupMessage: Identifiable, Codable, Sendable {
  public let id: String
  public var content: String
  public let groupId: String
  public let owner: String
  public let createdAt: Date
  public var updatedAt: Date

  public init(content: String, groupId: String, owner: String) {
    let now = Date()
    id = UUID().uuidString
    self.content = content
    self.groupId = groupId
    self.owner = owner
    createdAt = now
    updatedAt = now
  }

  public func withUpdatedContent(_ content: String) -> GroupMessage? {
    let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    var updated = self
    updated.content = trimmed
    updated.updatedAt = Date()
    return updated
  }
}

public extension GroupMessage {
  static let stub = GroupMessage(
    content: "안녕하세요1", groupId: User.stub.groupId, owner: User.stub.id,
  )
}
