//
//  TodoStatusChip.swift
//  TodoMate
//
//  Created by hs on 1/21/26.
//

import SwiftUI
import TodoMateDomain

struct TodoStatusChip: View {
  let status: TodoStatus
  var action: (() -> Void)?
  var isExpanded: Bool = false

  var body: some View {
    if let action {
      Button(action: action) { label }
        .buttonStyle(.plain)
    } else {
      label
    }
  }

  private var label: some View {
    ChipLabel(
      icon: status.iconName,
      text: status.description,
      isActive: status != .todo,
      color: status.color,
      isExpanded: isExpanded,
    )
  }
}
