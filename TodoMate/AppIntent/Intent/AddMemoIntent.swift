//
//  AddMemoIntent.swift
//  TodoMate
//
//  Created by agent on 1/16/26.
//

import AppIntents
import Foundation
import TodoMateDomain

struct AddMemoIntent: AppIntent {
  static var title: LocalizedStringResource = "Add Memo"
  static var description: IntentDescription? = "Creates a new Memo in TodoMate."

  @Parameter(title: "Content")
  var content: String

  static var parameterSummary: some ParameterSummary {
    Summary("Add Memo \(\.$content)")
  }

  func perform() async throws -> some IntentResult & ReturnsValue<MemoEntity> {
    guard let container = CoreDIContainer.shared else {
      throw AppIntentError.containerNotFound
    }

    // 로컬 Memo는 owner를 ""로 설정 (AppIntent는 Firebase 미사용)
    let memo = Memo(
      owner: "",
      content: content,
    )

    try await container.createLocalMemoUseCase.run(memo)

    let entity = MemoEntity(from: memo)
    return .result(value: entity)
  }
}
