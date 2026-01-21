//
//  UpdateTodoIntent.swift
//  TodoMate
//
//  Created by agent on 1/16/26.
//

import AppIntents
import Foundation
import TodoMateDomain

struct UpdateTodoIntent: AppIntent {
  static var title: LocalizedStringResource = "Update Todo"
  static var description: IntentDescription? = "Updates a Todo's status or content."

  @Parameter(title: "Todo")
  var todo: TodoEntity

  @Parameter(title: "New Status")
  var newStatus: TodoStatusParam?

  @Parameter(title: "New Content")
  var newContent: String?

  // AppEnum for TodoStatus
  enum TodoStatusParam: String, AppEnum {
    case todo = "시작 전"
    case inProgress = "진행 중"
    case complete = "완료"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Todo Status"
    static var caseDisplayRepresentations: [TodoStatusParam: DisplayRepresentation] = [
      .todo: "To Do",
      .inProgress: "In Progress",
      .complete: "Complete",
    ]

    var asDomain: TodoStatus {
      switch self {
      case .todo: .todo
      case .inProgress: .inProgress
      case .complete: .complete
      }
    }
  }

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<TodoEntity> {
    guard let container = CoreDIContainer.shared else {
      throw AppIntentError.containerNotFound
    }

    // Domain Todo로 변환하여 업데이트
    // 먼저 최신 상태 조회
    guard let currentTodo = try await container.localTodoRepository.read(id: todo.id) else {
      throw AppIntentError.todoNotFound(id: todo.id)
    }

    var updatedTodo = currentTodo

    if let newStatus {
      updatedTodo = updatedTodo.withUpdatedStatus(newStatus.asDomain)
    }

    if let newContent, !newContent.isEmpty {
      updatedTodo = updatedTodo.withUpdatedContent(newContent)
    }

    try await container.localTodoRepository.update(updatedTodo)

    return .result(value: TodoEntity(from: updatedTodo))
  }
}
