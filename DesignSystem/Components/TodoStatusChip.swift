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
  var forceInteractive: Bool = false

  var isInteractive: Bool {
    action != nil || forceInteractive
  }

  var body: some View {
    if let action {
      Button(action: action) {
        chipContent
      }
      .buttonStyle(.plain)
    } else {
      chipContent
    }
  }

  private var chipContent: some View {
    HStack {
      Spacer()
      Text(status.rawValue)
        .foregroundColor(isInteractive ? .primary : .secondary)
        .font(.caption)
        .fontWeight(.medium)
      Spacer()
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .frame(width: DesignSystem.StatusChip.width)
    .background(
      Capsule()
        .fill(
          status.color.opacity(
            isInteractive
              ? DesignSystem.StatusChip.interactiveOpacity
              : DesignSystem.StatusChip.readOnlyOpacity),
        )
        .shadow(
          color: status.color.opacity(0.2), radius: DesignSystem.StatusChip.shadowRadius, x: 0,
          y: 1,
        ),
    )
  }
}

#Preview {
  VStack(spacing: 16) {
    Text("Interactive")
    TodoStatusChip(status: .todo, action: { print("Tapped!") })

    Text("Read-only")
    TodoStatusChip(status: .complete)
  }
  .frame(width: 200, height: 200)
}
