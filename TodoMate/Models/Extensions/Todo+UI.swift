//
//  Todo+UI.swift
//  TodoMate
//
//  Created by agent on 1/13/26.
//

import CoreTransferable
import SwiftUI
import TodoMateDomain
import UniformTypeIdentifiers

extension TodoStatus {
  var displayName: String {
    switch self {
    case .todo: "To Do"
    case .inProgress: "In Progress"
    case .complete: "Done"
    case .inComplete: "Incomplete"
    }
  }

  var iconName: String {
    switch self {
    case .todo: "circle"
    case .inProgress: "arrow.right.circle"
    case .complete: "checkmark.circle"
    case .inComplete: "xmark.circle"
    }
  }

  var filledIconName: String {
    switch self {
    case .todo: "circle"
    case .inProgress: "arrow.right.circle.fill"
    case .complete: "checkmark.circle.fill"
    case .inComplete: "xmark.circle.fill"
    }
  }

  var displayColor: Color {
    switch self {
    case .todo: .secondary
    case .inProgress: DesignSystem.Colors.accentCyan
    case .complete: DesignSystem.Colors.accentGreen
    case .inComplete: DesignSystem.Colors.accentRed
    }
  }

  var color: Color { displayColor }

  var next: TodoStatus {
    switch self {
    case .todo: .inProgress
    case .inProgress: .complete
    case .complete: .todo
    case .inComplete: .todo
    }
  }
}

extension Todo {
  var isDone: Bool {
    status == .complete
  }
}

extension Todo: @retroactive Transferable {
  public static var transferRepresentation: some TransferRepresentation {
    CodableRepresentation(contentType: .todo)
  }
}

extension UTType {
  static var todo: UTType {
    UTType(exportedAs: "io.hotcs6.TodoMate.todo")
  }
}
