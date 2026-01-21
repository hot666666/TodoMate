//
//  ReadTodosIntent.swift
//  TodoMate
//
//  Created by agent on 1/16/26.
//

import AppIntents
import Foundation
import TodoMateDomain

struct ReadTodosIntent: AppIntent {
  static var title: LocalizedStringResource = "Show Todos"
  static var description: IntentDescription? = "Shows your local todos."

  // 필터링 옵션을 추가할 수 있음 (예: "오늘", "내일", "완료됨" 등)
  @Parameter(title: "Date Filter", default: .today)
  var dateFilter: DateFilterParam

  enum DateFilterParam: String, AppEnum {
    case today
    case all

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Date Filter"
    static var caseDisplayRepresentations: [DateFilterParam: DisplayRepresentation] = [
      .today: "Today",
      .all: "All",
    ]
  }

  @Dependency
  private var container: CoreDIContainer

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<[TodoEntity]> {
    // Repository에서 조회
    // Query 구성
    var query = TodoQuery()
    if dateFilter == .today {
      let today = Calendar.current.startOfDay(for: .now)
      guard
        let endOfDay = Calendar.current.date(
          bySettingHour: 23, minute: 59, second: 59, of: today,
        )
      else {
        throw AppIntentError.unknown
      }
      query = query.dateRange(today ... endOfDay)
    }

    let todos = try await container.localTodoRepository.readAll(
      query: query, useCache: true,
    )

    let entities = todos.map { TodoEntity(from: $0) }

    // EntityQuery의 suggestedEntities와 달리 실제 사용자가 요청한 데이터 반환
    return .result(value: entities)
  }
}
