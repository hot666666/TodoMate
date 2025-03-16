//
//  MessageDTO.swift
//  TodoMate
//
//  Created by hs on 3/15/25.
//

import Foundation

#if !PREVIEW
  import FirebaseFirestore
#endif

struct MessageDTO: Codable {
  #if !PREVIEW
    @DocumentID var id: String?
  #else
    var id: String?
  #endif
  var content: String
  var lastModifiedUser: String
  let createdAt: Date
  let lastModifiedAt: Date

  init(id: String? = nil, content: String = "", lastModifiedUser: String, createdAt: Date = .now) {
    self.id = id
    self.content = content
    self.lastModifiedUser = lastModifiedUser
    self.createdAt = createdAt
    lastModifiedAt = .now
  }
}

extension MessageDTO {
  static func from(_ message: MessageModel) -> MessageDTO {
    MessageDTO(
      id: message.fid,
      content: message.content,
      lastModifiedUser: message.lastModifiedUser,
      createdAt: message.createdAt
    )
  }
}

extension MessageDTO {
  static let stub: MessageDTO = .init(
    id: "fid1",
    content: "Hello",
    lastModifiedUser: "hs",
    createdAt: .now
  )
  static let stubs: [MessageDTO] = [.stub,
                                    .init(
                                      id: "fid2",
                                      content: "Hi",
                                      lastModifiedUser: "hs",
                                      createdAt: .now
                                    ),
                                    .init(
                                      id: "fid3",
                                      content: "Hey",
                                      lastModifiedUser: "hs",
                                      createdAt: .now
                                    )]
}
