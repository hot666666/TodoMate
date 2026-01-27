import Foundation
import GRDB
import TodoMateDomain

public struct GRDBMemo: Codable, FetchableRecord, PersistableRecord, Sendable {
  public var id: String
  public var content: String
  public var createdAt: Date
  public var updatedAt: Date
  public var ownerId: String
  public var isDeleted: Bool

  public static let databaseTableName = "memo"

  public init(from memo: Memo) {
    self.id = memo.id
    self.content = memo.content
    self.createdAt = memo.createdAt
    self.updatedAt = memo.updatedAt
    self.ownerId = memo.owner
    self.isDeleted = memo.isDeleted
  }

  public func toDomain() -> Memo {
    Memo(
      id: id,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      owner: ownerId,
      isDeleted: isDeleted
    )
  }
}
