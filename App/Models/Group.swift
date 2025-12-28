//
//  Group.swift
//  TodoMate
//
//  Created by agent on 12/28/25.
//

import FirebaseFirestore

struct Group: Identifiable, Codable, Hashable {
  @DocumentID var id: String?
  var name: String
  var memberIds: [String]
  var inviteCode: String

  @ServerTimestamp var createdAt: Date?
  @ServerTimestamp var updatedAt: Date?

  init(
    id: String? = nil,
    name: String,
    memberIds: [String] = [],
    inviteCode: String = "",
  ) {
    self.id = id
    self.name = name
    self.memberIds = memberIds
    self.inviteCode = inviteCode
  }
}
