//
//  AddTodoIntent.swift
//  TodoMate
//
//  Created by agent on 1/16/26.
//

import AppIntents
import Foundation
import TodoMateDomain

struct AddTodoIntent: AppIntent {
  static var title: LocalizedStringResource = "Add Todo"
  static var description: IntentDescription? = "Creates a new Todo in TodoMate."

  @Parameter(title: "Content")
  var content: String

  @Parameter(title: "Detail", requestValueDialog: "Any details?")
  var detail: String?

  @Parameter(title: "Date", default: .now)
  var date: Date

  static var parameterSummary: some ParameterSummary {
    Summary("Add \(\.$content)") {
      \.$date
      \.$detail
    }
  }

  func perform() async throws -> some IntentResult & ReturnsValue<TodoEntity> {
    guard let container = CoreDIContainer.shared else {
      throw AppIntentError.containerNotFound
    }

    // 로컬 Todo는 owner를 ""로 설정 (AppIntent는 Firebase 미사용)

    let todo = Todo(
      owner: "",
      content: content,
      detail: detail ?? "",
      in: date,
    )

    try await container.createLocalTodoUseCase.run(todo)

    let entity = TodoEntity(from: todo)
    return .result(value: entity)
  }
}
