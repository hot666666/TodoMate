//
//  ChatMessage.swift
//  TodoMate
//
//  Created by agent on 1/3/26.
//

import FirebaseFirestore
import Foundation

struct ChatMessage: Identifiable, Codable, Hashable {
  @DocumentID var id: String?
  let groupId: String
  let senderId: String
  let text: String?
  let imageUrl: String?

  // For local preview while uploading (not persisted)
  var localImageData: Data?

  @ServerTimestamp var createdAt: Date?

  init(
    id: String? = nil,
    groupId: String,
    senderId: String,
    text: String? = nil,
    imageUrl: String? = nil,
    localImageData: Data? = nil,
  ) {
    self.id = id
    self.groupId = groupId
    self.senderId = senderId
    self.text = text
    self.imageUrl = imageUrl
    self.localImageData = localImageData
  }
}
