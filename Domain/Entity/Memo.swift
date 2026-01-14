//
//  Memo.swift
//  Todo
//
//  Created by hs on 7/8/25.
//

import Foundation

struct Memo: Identifiable, Codable, Equatable, Hashable {
  let id: String
  /// DocumentID
  var content: String
  let createdAt: Date
  var updatedAt: Date
  let owner: String
  /// UserID
  var isDeleted: Bool

  init(
    id: String = UUID().uuidString,
    content: String = "",
    createdAt: Date,
    updatedAt: Date,
    owner: String,
    isDeleted: Bool = false,
  ) {
    self.id = id
    self.content = content
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.owner = owner
    self.isDeleted = isDeleted
  }

  init(owner: String, content: String = "") {
    let now = Date()
    self.init(
      id: UUID().uuidString,
      content: content,
      createdAt: now,
      updatedAt: now,
      owner: owner,
    )
  }

  static func == (lhs: Memo, rhs: Memo) -> Bool {
    lhs.id == rhs.id
      && lhs.content == rhs.content
      && lhs.owner == rhs.owner
      && lhs.createdAt == rhs.createdAt
      && lhs.updatedAt == rhs.updatedAt
  }

  func withUpdatedContent(_ newContent: String) -> Memo {
    var updated = self
    updated.content = newContent
    updated.updatedAt = .now
    return updated
  }

  // MARK: - Codable Compatibility

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    content = try container.decode(String.self, forKey: .content)
    createdAt = try container.decode(Date.self, forKey: .createdAt)
    updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    owner = try container.decode(String.self, forKey: .owner)
    isDeleted = try container.decodeIfPresent(Bool.self, forKey: .isDeleted) ?? false
  }
}

extension Memo {
  static let stub = Memo(
    id: UUID().uuidString,
    content: "# 샘플 메모\n\n- 첫 번째 항목\n- 두 번째 항목\n\n**볼드 텍스트**와 *이탤릭 텍스트*",
    createdAt: .now,
    updatedAt: .now,
    owner: EntityConstant.User.stubId,
  )
}

extension Memo {
  var isEmpty: Bool { content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
  var wordCount: Int {
    content.components(separatedBy: .whitespacesAndNewlines).count(where: { !$0.isEmpty })
  }

  static func empty(for userId: String) -> Memo {
    Memo(owner: userId, content: "")
  }

  func with(content: String) -> Memo {
    withUpdatedContent(content)
  }
}
