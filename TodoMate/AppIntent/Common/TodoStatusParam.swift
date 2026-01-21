//
//  TodoStatusParam.swift
//  TodoMate
//
//  Created by agent on 1/21/26.
//

import AppIntents
import Foundation
import TodoMateDomain

enum TodoStatusParam: String, AppEnum {
  case inComplete = "미완료"
  case todo = "시작 전"
  case inProgress = "진행 중"
  case complete = "완료"

  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Todo Status"
  static var caseDisplayRepresentations: [TodoStatusParam: DisplayRepresentation] = [
    .inComplete: "Incomplete",
    .todo: "To Do",
    .inProgress: "In Progress",
    .complete: "Complete",
  ]

  var asDomain: TodoStatus {
    switch self {
    case .inComplete: .inComplete
    case .todo: .todo
    case .inProgress: .inProgress
    case .complete: .complete
    }
  }
}
