//
//  Todo.swift
//  Todo
//
//  Created by hs on 5/24/25.
//

import SwiftUI

enum TodoStatus: String, CaseIterable, Codable, CustomStringConvertible {
  case inComplete = "미완료"
  case todo = "시작 전"
  case inProgress = "진행 중"
  case complete = "완료"

  var description: String { rawValue }

  var color: Color {
    switch self {
    case .todo: .gray
    case .inProgress: .blue
    case .complete: .green
    case .inComplete: .red
    }
  }

  var iconName: String {
    switch self {
    case .todo: "circle"
    case .inProgress: "circle.inset.filled"
    case .complete: "checkmark.circle.fill"
    case .inComplete: "xmark.circle.fill"
    }
  }
}

struct Todo: Identifiable, Codable {
  let id: String
  /// DocumentID
  var content: String
  var status: TodoStatus
  var detail: String
  var date: Date
  let createdAt: Date
  var updatedAt: Date
  let owner: String
  /// UserID
  var isDeleted: Bool

  init(
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

  init(owner: String, content: String = "", detail: String = "", in date: Date? = nil) {
    let now = date ?? Date()
    self.init(
      id: UUID().uuidString,
      content: content,
      status: .todo,
      detail: detail,
      date: Calendar.current.startOfDay(for: now),
      createdAt: now,
      updatedAt: now,
      owner: owner,
    )
  }

  static func == (lhs: Todo, rhs: Todo) -> Bool {
    lhs.date == rhs.date
      && lhs.content == rhs.content
      && lhs.status == rhs.status
      && lhs.detail == rhs.detail
      && lhs.owner == rhs.owner
      && lhs.id == rhs.id
  }

  func withUpdatedStatus(_ newStatus: TodoStatus) -> Todo {
    var updated = self
    updated.status = newStatus
    updated.updatedAt = .now
    return updated
  }

  func withUpdatedContent(_ newContent: String) -> Todo {
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
    status = try container.decode(TodoStatus.self, forKey: .status)
    detail = try container.decode(String.self, forKey: .detail)
    date = try container.decode(Date.self, forKey: .date)
    createdAt = try container.decode(Date.self, forKey: .createdAt)
    updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    owner = try container.decode(String.self, forKey: .owner)
    isDeleted = try container.decodeIfPresent(Bool.self, forKey: .isDeleted) ?? false
  }
}

extension Todo {
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
