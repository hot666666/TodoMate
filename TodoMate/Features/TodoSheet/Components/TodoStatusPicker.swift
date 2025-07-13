//
//  TodoStatusPicker.swift
//  Todo
//
//  Created by hs on 6/29/25.
//

import SwiftUI

struct TodoStatusPicker: View {
  let selectedStatus: TodoStatus
  let onStatusSelected: (TodoStatus) -> Void

  var body: some View {
    VStack(spacing: TodoSheetDesignSystem.Spacing.small) {
      ForEach(TodoStatus.allCases, id: \.self) { status in
        TodoStatusChip(status: status, action: {
          onStatusSelected(status)
        })
      }
    }
    .padding(TodoSheetDesignSystem.Padding.small)
    .frame(width: TodoSheetDesignSystem.Component.StatusPicker.width, height: TodoSheetDesignSystem.Component.StatusPicker.height)
  }
}

#Preview {
  TodoStatusPicker(
    selectedStatus: .todo,
    onStatusSelected: { status in
      print("Selected: \(status)")
    }
  )
  .frame(width: 100, height: 200)
}
