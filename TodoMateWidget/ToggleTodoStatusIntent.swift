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
import SwiftData
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

  @MainActor
  func perform() async throws -> some IntentResult {
    // Intent는 MainActor가 아니므로 Task로 감싸거나, 독립적으로 생성해야 함.
    // 하지만 WidgetDataContainer는 @MainActor이므로 여기서는 독립 생성하되,
    // 동일한 구성을 사용하여 충돌 최소화.
    // *주의*: Intent는 백그라운드에서 돌 수 있어 MainActor 제약이 있는 싱글톤 접근이 어려울 수 있음.
    // 여기서는 안전하게 독립 생성하되 스키마만 일치시킴.

    let schema = Schema([SDTodo.self, SDMemo.self])
    let config = ModelConfiguration(
      AppEnvironment.Container.name,
      schema: schema,
      isStoredInMemoryOnly: false,
    )

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
