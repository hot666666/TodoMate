//
//  AddTodoIntent.swift
//  TodoMate
//
//  Created by agent on 1/16/26.
//

import AppIntents
import Common
import Foundation
import TodoMateDomain
import WidgetKit

struct AddTodoIntent: AppIntent {
  #if DEBUG
    static let title: LocalizedStringResource = "Add Todo DEBUG"
  #else
    static let title: LocalizedStringResource = "Add Todo"
  #endif
  static let description: IntentDescription? = "Creates a new Todo in TodoMate."

  @Parameter(title: "Content")
  var content: String

  @Parameter(title: "Detail", requestValueDialog: "Any details?")
  var detail: String?

  @Parameter(title: "Date", default: .now)
  var date: Date

  @Parameter(title: "Status", default: .todo)
  var status: TodoStatusParam

  static var parameterSummary: some ParameterSummary {
    Summary("Add \(\.$content)") {
      \.$date
      \.$detail
      \.$status
    }
  }

  @Dependency
  private var container: CoreDIContainer

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<TodoEntity> {
    let sanitizedContent = content.replacingOccurrences(of: "\n", with: " ")

    let todo = Todo(
      owner: User.local.id,
      content: sanitizedContent,
      status: status.asDomain,
      detail: detail ?? "",
      in: date,
    )

    try await container.createLocalTodoUseCase.run(todo)
    WidgetCenter.shared.reloadTimelines(ofKind: AppEnvironment.Widget.kind)

    let entity = TodoEntity(from: todo)
    return .result(value: entity)
  }
}
