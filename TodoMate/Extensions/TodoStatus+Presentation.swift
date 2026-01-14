import SwiftUI

public extension TodoStatus {
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
