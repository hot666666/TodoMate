//
//  SDMemo.swift
//  TodoMateDomain
//
//  SwiftData model for Memo persistence.
//
//  Created by agent on 1/11/26.
//

import Foundation
import SwiftData
import TodoMateDomain

@Model
public final class SDMemo {
  @Attribute(.unique) public var id: String
  public var content: String
  public var createdAt: Date
  public var updatedAt: Date
  public var ownerId: String
  public var isDeleted: Bool

  public init(
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

  /// Domain Entity -> SwiftData Model
  convenience init(from memo: Memo) {
    self.init(
      id: memo.id,
      content: memo.content,
      createdAt: memo.createdAt,
      updatedAt: memo.updatedAt,
      ownerId: memo.owner,
      isDeleted: memo.isDeleted,
    )
  }

  public func toDomain() -> Memo {
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
