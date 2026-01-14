//
//  TodoStatus+.swift
//  TodoMate
//
//  Created by hs on 1/14/26.
//

import SwiftUI
import TodoMateDomain

extension TodoStatus {
  var color: Color {
    switch self {
    case .todo: .gray
    case .inProgress: .blue
    case .complete: .green
    case .inComplete: .red
    }
  }

  var iconName: String {
    switch self {
    case .todo: "circle"
    case .inProgress: "circle.inset.filled"
    case .complete: "checkmark.circle.fill"
    case .inComplete: "xmark.circle.fill"
    }
  }
}
