import Foundation
import GRDB
import TodoMateDomain

extension TodoStatus: @retroactive DatabaseValueConvertible {}

struct TodoRecord: Codable, Equatable, FetchableRecord, PersistableRecord, Identifiable, Sendable {
  static let databaseTableName = "todo"

  enum CodingKeys: String, CodingKey {
    case id
    case content
    case status
    case detail
    case date
    case createdAt
    case updatedAt
    case ownerID = "ownerId"
    case deletedAt
    case localRevision
  }

  enum Columns {
    static let id = Column(CodingKeys.id)
    static let content = Column(CodingKeys.content)
    static let status = Column(CodingKeys.status)
    static let detail = Column(CodingKeys.detail)
    static let date = Column(CodingKeys.date)
    static let createdAt = Column(CodingKeys.createdAt)
    static let updatedAt = Column(CodingKeys.updatedAt)
    static let ownerID = Column(CodingKeys.ownerID)
    static let deletedAt = Column(CodingKeys.deletedAt)
    static let localRevision = Column(CodingKeys.localRevision)
  }

  var id: String
  var content: String
  var status: TodoStatus
  var detail: String
  var date: Date
  var createdAt: Date
  var updatedAt: Date
  var ownerID: String
  var deletedAt: Date?
  /// Monotonic row version in this local database; it is not a Nostr event revision.
  var localRevision: Int64

  init(
    id: String,
    content: String,
    status: TodoStatus,
    detail: String,
    date: Date,
    createdAt: Date,
    updatedAt: Date,
    ownerID: String,
    deletedAt: Date?,
    localRevision: Int64 = 1,
  ) {
    self.id = id
    self.content = content
    self.status = status
    self.detail = detail
    self.date = date
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.ownerID = ownerID
    self.deletedAt = deletedAt
    self.localRevision = localRevision
  }

  init(_ todo: Todo) {
    id = todo.id
    content = todo.content
    status = todo.status
    detail = todo.detail
    date = todo.date
    createdAt = todo.createdAt
    updatedAt = todo.updatedAt
    ownerID = todo.owner
    deletedAt = todo.isDeleted ? todo.updatedAt : nil
    localRevision = 1
  }

  mutating func apply(_ todo: Todo, at modificationDate: Date) {
    content = todo.content
    status = todo.status
    detail = todo.detail
    date = todo.date
    ownerID = todo.owner
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

  func domainValue() -> Todo {
    Todo(
      id: id,
      content: content,
      status: status,
      detail: detail,
      date: date,
      createdAt: createdAt,
      updatedAt: updatedAt,
      owner: ownerID,
      isDeleted: deletedAt != nil,
    )
  }
}

extension TodoRecord {
  static func activeRequest(for query: TodoQuery) -> QueryInterfaceRequest<TodoRecord> {
    var request = filter(Columns.deletedAt == nil)
      .order(Columns.date, Columns.createdAt)

    for filter in query.filters {
      switch filter {
      case let .owner(userID):
        request = request.filter(Columns.ownerID == userID)
      case let .owners(userIDs):
        request = userIDs.isEmpty
          ? request.none()
          : request.filter(userIDs.contains(Columns.ownerID))
      case let .dateRange(range):
        request = request.filter(Columns.date >= range.lowerBound && Columns.date <= range.upperBound)
      case let .status(status):
        request = request.filter(Columns.status == status)
      }
    }
    return request
  }
}
