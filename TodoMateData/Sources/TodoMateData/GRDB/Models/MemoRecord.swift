import Foundation
import GRDB
import TodoMateDomain

struct MemoRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
  static let databaseTableName = "memo"

  var id: String
  var content: String
  var createdAt: Date
  var updatedAt: Date
  var owner: String
  var isDeleted: Bool

  init(
    id: String,
    content: String,
    createdAt: Date,
    updatedAt: Date,
    owner: String,
    isDeleted: Bool,
  ) {
    self.id = id
    self.content = content
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.owner = owner
    self.isDeleted = isDeleted
  }

  init(_ memo: Memo) {
    id = memo.id
    content = memo.content
    createdAt = memo.createdAt
    updatedAt = memo.updatedAt
    owner = memo.owner
    isDeleted = memo.isDeleted
  }

  func domainValue() -> Memo {
    Memo(
      id: id,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      owner: owner,
      isDeleted: isDeleted,
    )
  }
}
