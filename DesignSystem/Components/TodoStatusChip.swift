//
//  TodoStatusChip.swift
//  Todo
//
//  Created by hs on 6/13/25.
//

import SwiftUI

struct TodoStatusChip: View {
  let status: TodoStatus
  var action: (() -> Void)?
  var isExpanded: Bool = false

  var body: some View {
    if let action {
      Button(action: action) {
        label
      }
      .buttonStyle(.plain)
    } else {
      label
    }
  }

  private var label: some View {
    TagButtonLabel(
      icon: status.iconName,
      text: status.description,
      isActive: status != .todo,
      activeColor: status.color,
      isExpanded: isExpanded,
    )
  }
}

#Preview {
  VStack(spacing: 16) {
    Text("Interactive")
    TodoStatusChip(status: .todo, action: { print("Tapped!") })

    Text("Read-only")
    TodoStatusChip(status: .complete)
    TodoStatusChip(status: .inProgress, isExpanded: true)
  }
  .frame(width: 200, height: 200)
}
