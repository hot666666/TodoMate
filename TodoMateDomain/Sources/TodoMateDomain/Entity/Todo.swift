//
//  Todo.swift
//  Todo
//
//  Created by hs on 5/24/25.
//

import Foundation

public enum TodoStatus: String, CaseIterable, Codable, CustomStringConvertible, Sendable {
  case todo = "시작 전"
  case inProgress = "진행 중"
  case complete = "완료"
  case inComplete = "미완료"

  public var description: String { rawValue }
}

public struct Todo: Identifiable, Codable, Sendable {
  public let id: String
  /// DocumentID
  public var content: String
  public var status: TodoStatus
  public var detail: String
  public var date: Date
  public let createdAt: Date
  public var updatedAt: Date
  public let owner: String
  /// UserID
  public var isDeleted: Bool

  public init(
    id: String = UUID().uuidString,
    content: String = "",
    status: TodoStatus = .todo,
    detail: String = "",
    date: Date = .now,
    createdAt: Date,
    updatedAt: Date,
    owner: String,
    isDeleted: Bool = false,
  ) {
    self.id = id
    self.content = content
    self.status = status
    self.detail = detail
    self.date = Calendar.current.startOfDay(for: date)
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.owner = owner
    self.isDeleted = isDeleted
  }

  public init(
    owner: String, content: String = "", status: TodoStatus = .todo, detail: String = "",
    in date: Date? = nil,
  ) {
    let now = date ?? Date()
    self.init(
      id: UUID().uuidString,
      content: content,
      status: status,
      detail: detail,
      date: Calendar.current.startOfDay(for: now),
      createdAt: now,
      updatedAt: now,
      owner: owner,
    )
  }

  public static func == (lhs: Todo, rhs: Todo) -> Bool {
    lhs.date == rhs.date
      && lhs.content == rhs.content
      && lhs.status == rhs.status
      && lhs.detail == rhs.detail
      && lhs.owner == rhs.owner
      && lhs.id == rhs.id
  }

  public func withUpdatedStatus(_ newStatus: TodoStatus) -> Todo {
    var updated = self
    updated.status = newStatus
    updated.updatedAt = .now
    return updated
  }

  public func withUpdatedContent(_ newContent: String) -> Todo {
    var updated = self
    updated.content = newContent
    updated.updatedAt = .now
    return updated
  }

  // MARK: - Codable Compatibility

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    content = try container.decode(String.self, forKey: .content)
    status = try container.decode(TodoStatus.self, forKey: .status)
    detail = try container.decode(String.self, forKey: .detail)
    date = try container.decode(Date.self, forKey: .date)
    createdAt = try container.decode(Date.self, forKey: .createdAt)
    updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    owner = try container.decode(String.self, forKey: .owner)
    isDeleted = try container.decodeIfPresent(Bool.self, forKey: .isDeleted) ?? false
  }
}

public extension Todo {
  var contentOrPlaceholder: String { content.isEmpty ? "이름없음" : content }
  var compactDetail: String {
    let strippedDetail = detail.replacingOccurrences(of: "\n", with: " ")
    let maxLength = 20
    if strippedDetail.count > maxLength {
      let index = strippedDetail.index(strippedDetail.startIndex, offsetBy: maxLength)
      return String(strippedDetail[..<index]) + "..."
    } else {
      return strippedDetail
    }
  }

  static let stub = Todo(
    id: UUID().uuidString,
    content: "Sample Todo",
    date: .now,
    createdAt: .now,
    updatedAt: .now,
    owner: "stubUser",
  )

  static func copy(from todo: Todo) -> Todo {
    let now: Date = .now
    return Todo(
      id: UUID().uuidString,
      content: todo.content,
      status: .todo,
      detail: todo.detail,
      date: todo.date,
      createdAt: now,
      updatedAt: now,
      owner: todo.owner,
    )
  }
}
