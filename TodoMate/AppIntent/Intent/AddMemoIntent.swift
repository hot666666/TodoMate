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
  #if DEBUG
    static var title: LocalizedStringResource = "Add Memo DEBUG"
  #else
    static var title: LocalizedStringResource = "Add Memo"
  #endif
  static var description: IntentDescription? = "Creates a new Memo in TodoMate."

  @Parameter(title: "Content")
  var content: String

  static var parameterSummary: some ParameterSummary {
    Summary("Add Memo \(\.$content)")
  }

  @Dependency
  private var container: CoreDIContainer

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<MemoEntity> {
    // 로컬 Memo는 owner를 ""로 설정
    let memo = Memo(
      owner: "",
      content: content,
    )

    try await container.createLocalMemoUseCase.run(memo)

    let entity = MemoEntity(from: memo)
    return .result(value: entity)
  }
}
