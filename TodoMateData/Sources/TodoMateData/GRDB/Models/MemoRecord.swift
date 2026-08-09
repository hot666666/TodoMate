import Foundation
import GRDB
import TodoMateDomain

struct MemoRecord: Codable, FetchableRecord, PersistableRecord, Identifiable, Sendable {
  static let databaseTableName = "memo"

  enum CodingKeys: String, CodingKey {
    case id
    case content
    case createdAt
    case updatedAt
    case ownerID = "ownerId"
    case deletedAt
    case localRevision
  }

  enum Columns {
    static let id = Column(CodingKeys.id)
    static let content = Column(CodingKeys.content)
    static let createdAt = Column(CodingKeys.createdAt)
    static let updatedAt = Column(CodingKeys.updatedAt)
    static let ownerID = Column(CodingKeys.ownerID)
    static let deletedAt = Column(CodingKeys.deletedAt)
    static let localRevision = Column(CodingKeys.localRevision)
  }

  var id: String
  var content: String
  var createdAt: Date
  var updatedAt: Date
  var ownerID: String
  var deletedAt: Date?
  /// Monotonic row version in this local database; it is not a Nostr event revision.
  var localRevision: Int64

  init(
    id: String,
    content: String,
    createdAt: Date,
    updatedAt: Date,
    ownerID: String,
    deletedAt: Date?,
    localRevision: Int64 = 1,
  ) {
    self.id = id
    self.content = content
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.ownerID = ownerID
    self.deletedAt = deletedAt
    self.localRevision = localRevision
  }

  init(_ memo: Memo) {
    id = memo.id
    content = memo.content
    createdAt = memo.createdAt
    updatedAt = memo.updatedAt
    ownerID = memo.owner
    deletedAt = memo.isDeleted ? memo.updatedAt : nil
    localRevision = 1
  }

  mutating func apply(_ memo: Memo, at modificationDate: Date) {
    content = memo.content
    ownerID = memo.owner
    updatedAt = modificationDate
    localRevision += 1
  }

  mutating func markDeleted(at deletionDate: Date) -> Bool {
    guard deletedAt == nil else { return false }
    deletedAt = deletionDate
    updatedAt = deletionDate
    localRevision += 1
    return true
  }

  mutating func restore(at restorationDate: Date) -> Bool {
    guard deletedAt != nil else { return false }
    deletedAt = nil
    updatedAt = restorationDate
    localRevision += 1
    return true
  }

  func domainValue() -> Memo {
    Memo(
      id: id,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      owner: ownerID,
      isDeleted: deletedAt != nil,
    )
  }
}
