//
//  ToggleTodoStatusIntent.swift
//  TodoMateWidget
//
//  AppIntent for marking a todo as complete from widget.
//
//  Created by hs on 1/15/26.
//

import AppIntents
import SwiftData
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
    let schema = Schema([SDTodo.self])
    let config = ModelConfiguration(for: SDTodo.self)

    do {
      let container = try ModelContainer(for: schema, configurations: [config])
      let context = ModelContext(container)

      let targetId = todoId
      let predicate = #Predicate<SDTodo> { todo in
        todo.id == targetId
      }

      var descriptor = FetchDescriptor(predicate: predicate)
      descriptor.fetchLimit = 1

      if let sdTodo = try context.fetch(descriptor).first {
        sdTodo.statusRawValue = "완료"
        sdTodo.updatedAt = Date()
        try context.save()
      }
    } catch {
      // Silently fail - widget doesn't have logging
    }

    WidgetCenter.shared.reloadAllTimelines()
    return .result()
  }
}
