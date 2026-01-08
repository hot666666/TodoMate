//
//  ViewTodo.swift
//  TodoMate
//
//  Presentation layer model that wraps Domain Todo entity
//  for use in Views with additional display properties.
//
//  Created by agent on 1/5/26.
//

import SwiftUI

// MARK: - View Todo Status

/// Simplified status for display purposes
enum ViewTodoStatus: String, CaseIterable, Codable {
  case todo
  case inProgress
  case done
  case inComplete

  init(from status: TodoStatus) {
    switch status {
    case .todo:
      self = .todo
    case .inProgress:
      self = .inProgress
    case .complete:
      self = .done
    case .inComplete:
      self = .inComplete
    }
  }

  var displayColor: Color {
    switch self {
    case .todo: .gray
    case .inProgress: DesignSystem.Colors.accentCyan
    case .done: DesignSystem.Colors.accentGreen
    case .inComplete: DesignSystem.Colors.accentRed
    }
  }

  var iconName: String {
    switch self {
    case .todo: "circle"
    case .inProgress: "circle"
    case .done: "checkmark.circle.fill"
    case .inComplete: "xmark.circle.fill"
    }
  }

  var displayName: String {
    switch self {
    case .todo: "할 일"
    case .inProgress: "진행 중"
    case .done: "완료"
    case .inComplete: "미완료"
    }
  }

  func toDomainStatus() -> TodoStatus {
    switch self {
    case .todo: .todo
    case .inProgress: .inProgress
    case .done: .complete
    case .inComplete: .inComplete
    }
  }
}

// MARK: - View Todo

/// Presentation layer model for Todo
struct ViewTodo: Identifiable, Codable {
  let id: String
  var groupId: String?
  let owner: String
  var content: String
  var status: ViewTodoStatus
  var detail: String
  var date: Date
  var tags: [String]

  /// Initialize from Domain Todo entity
  init(from todo: Todo) {
    id = todo.id
    groupId = nil // Current domain model doesn't have groupId
    owner = todo.owner
    content = todo.content
    status = ViewTodoStatus(from: todo.status)
    detail = todo.detail
    date = todo.date
    tags = [] // Current domain model doesn't have tags
  }

  /// Mock initializer for previews
  init(
    id: String = UUID().uuidString,
    groupId: String? = nil,
    owner: String,
    content: String,
    status: ViewTodoStatus = .todo,
    detail: String = "",
    date: Date = .now,
    tags: [String] = [],
  ) {
    self.id = id
    self.groupId = groupId
    self.owner = owner
    self.content = content
    self.status = status
    self.detail = detail
    self.date = date
    self.tags = tags
  }
}

// MARK: - Transferable Conformance (for drag & drop)

extension ViewTodo: Transferable {
  static var transferRepresentation: some TransferRepresentation {
    CodableRepresentation(contentType: .json)
  }
}

// MARK: - Mock Data

extension ViewTodo {
  static let mockTodos: [ViewTodo] = [
    ViewTodo(
      id: "1",
      owner: "user1",
      content: "Define Liquid Glass components",
      status: .todo,
      detail: "Create standard blurred backgrounds and border radius tokens.",
      date: .now,
      tags: ["Design System"],
    ),
    ViewTodo(
      id: "2",
      owner: "user1",
      content: "Fix sidebar navigation bug",
      status: .todo,
      detail: "Dropdown menus are not closing when clicking outside.",
      date: .now,
      tags: ["Urgent"],
    ),
    ViewTodo(
      id: "3",
      owner: "user1",
      content: "Implement Dark Mode",
      status: .inProgress,
      detail: "Ensure all views have the dark mode variant.",
      date: .now,
      tags: ["Frontend"],
    ),
    ViewTodo(
      id: "4",
      owner: "user1",
      content: "Setup Project Repo",
      status: .done,
      detail: "",
      date: Date().addingTimeInterval(-86400),
      tags: ["DevOps"],
    ),
  ]

  static var todoTasks: [ViewTodo] {
    mockTodos.filter { $0.status == .todo }
  }

  static var inProgressTasks: [ViewTodo] {
    mockTodos.filter { $0.status == .inProgress }
  }

  static var doneTasks: [ViewTodo] {
    mockTodos.filter { $0.status == .done }
  }

  static var inCompleteTasks: [ViewTodo] {
    mockTodos.filter { $0.status == .inComplete }
  }
}
