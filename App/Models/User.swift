//
//  User.swift
//  TodoMate
//
//  Created by agent on 12/28/25.
//

import FirebaseFirestore

struct User: Codable, Identifiable, Hashable {
  @DocumentID var id: String?
  var displayName: String
  var email: String
  var avatarUrl: String?
  var groupId: String?
  var fcmToken: String?
  var authorized: Bool

  @ServerTimestamp var createdAt: Date?
  @ServerTimestamp var updatedAt: Date?

  /// 익명 유저 생성용 초기화
  init(
    id: String,
    displayName: String = "Guest",
    email: String = "",
    avatarUrl: String? = nil,
    groupId: String? = nil,
    fcmToken: String? = nil,
    authorized: Bool = false,
  ) {
    self.id = id
    self.displayName = displayName
    self.email = email
    self.avatarUrl = avatarUrl
    self.groupId = groupId
    self.fcmToken = fcmToken
    self.authorized = authorized
  }
}
