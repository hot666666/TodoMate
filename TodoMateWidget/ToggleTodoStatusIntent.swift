//
//  ToggleTodoStatusIntent.swift
//  TodoMateWidget
//
//  AppIntent for marking a todo as complete from widget.
//
//  Created by hs on 1/15/26.
//

import AppIntents
import Common
import TodoMateData
import TodoMateDomain
import WidgetKit

/// AppIntent to toggle a todo's status to complete from the widget
struct ToggleTodoStatusIntent: AppIntent {
  static var title: LocalizedStringResource = "할 일 완료"
  static var description = IntentDescription("진행 중인 할 일을 완료 처리합니다")

  @Parameter(title: "Todo ID")
  var todoId: String

  init() {}

  init(todoId: String) {
    self.todoId = todoId
  }

  func perform() async throws -> some IntentResult {
    do {
      let repository = WidgetDataContainer.todoRepository
      if var todo = try await repository.read(id: todoId) {
        todo.status = .complete
        todo.updatedAt = .now
        try await repository.update(todo)
      }
    } catch {
      Log.error("Widget todo update failed: \(error)", category: .data)
    }

    WidgetCenter.shared.reloadAllTimelines()
    return .result()
  }
}
