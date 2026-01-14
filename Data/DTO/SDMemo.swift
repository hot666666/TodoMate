//
//  SDMemo.swift
//  TodoMate
//
//  Created by agent on 1/11/26.
//

import Foundation
import SwiftData

@Model
final class SDMemo {
  @Attribute(.unique) var id: String
  var content: String
  var createdAt: Date
  var updatedAt: Date
  var ownerId: String
  var isDeleted: Bool

  init(
    id: String = UUID().uuidString,
    content: String,
    createdAt: Date = Date(),
    updatedAt: Date = Date(),
    ownerId: String,
    isDeleted: Bool = false,
  ) {
    self.id = id
    self.content = content
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.ownerId = ownerId
    self.isDeleted = isDeleted
  }

  func toDomain() -> Memo {
    Memo(
      id: id,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      owner: ownerId,
      isDeleted: isDeleted,
    )
  }
}

extension Memo {
  func toSDMemo() -> SDMemo {
    SDMemo(
      id: id,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      ownerId: owner,
      isDeleted: isDeleted,
    )
  }
}
