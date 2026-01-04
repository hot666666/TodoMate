//
//  Todo.swift
//  TodoMate
//
//  Created by agent on 12/28/25.
//

import FirebaseFirestore

struct Todo: Identifiable, Codable, Hashable {
  @DocumentID var id: String?
  let groupId: String?
  let owner: String

  var content: String
  var status: TodoStatus
  var detail: String
  var date: Date
  var tags: [String]

  @ServerTimestamp var createdAt: Date?
  @ServerTimestamp var updatedAt: Date?

  init(
    id: String? = nil,
    groupId: String?,
    owner: String,
    content: String,
    status: TodoStatus = .todo,
    detail: String = "",
    date: Date = .now,
    tags: [String] = [],
  ) {
    self.id = id
    self.groupId = groupId
    self.owner = owner
    self.content = content
    self.status = status
    self.detail = detail
    self.date = date
    self.tags = tags
  }

  /// owner 검증 - 해당 userId가 이 Todo의 소유자인지 확인
  func isOwned(by userId: String?) -> Bool {
    guard let userId, !userId.isEmpty else { return false }
    return owner == userId
  }
}
