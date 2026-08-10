//
//  UpdateTodoIntent.swift
//  TodoMate
//
//  Created by agent on 1/16/26.
//

import AppIntents
import Common
import Foundation
import TodoMateDomain

struct UpdateTodoIntent: AppIntent {
  #if DEBUG
    static var title: LocalizedStringResource = "Update Todo DEBUG"
  #else
    static var title: LocalizedStringResource = "Update Todo"
  #endif
  static var description: IntentDescription? = "Updates a Todo's status or content."

  @Parameter(title: "Todo")
  var todo: TodoEntity

  @Parameter(title: "New Status")
  var newStatus: TodoStatusParam?

  @Parameter(title: "New Content")
  var newContent: String?

  @Dependency
  private var container: CoreDIContainer

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<TodoEntity> {
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
