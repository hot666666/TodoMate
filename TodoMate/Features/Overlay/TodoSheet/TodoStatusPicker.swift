//
//  TodoStatusPicker.swift
//  TodoMate
//
//  Created by hs on 1/21/26.
//

import SwiftUI
import TodoMateDomain

struct TodoStatusPicker: View {
  // MARK: - Properties

  @Binding var selectedStatus: TodoStatus
  var onDismiss: () -> Void

  private var statusOptions: [TodoStatus] {
    TodoStatus.allCases.filter { $0 != selectedStatus }
  }

  // MARK: - Body

  var body: some View {
    VStack(spacing: DesignSystem.TodoSheet.Spacing.small) {
      ForEach(statusOptions, id: \.self) { status in
        statusRow(for: status)
      }
    }
    .padding(DesignSystem.TodoSheet.Padding.small)
    .materialCardOverlay()
    .onKeyPress(.escape) {
      onDismiss()
      return .handled
    }
  }

  // MARK: - Subviews

  private func statusRow(for status: TodoStatus) -> some View {
    HStack {
      TodoStatusChip(
        status: status,
        action: {
          selectedStatus = status
          onDismiss()
        },
        isExpanded: true,
      )
    }
    .contentShape(.rect)
  }
}

#Preview {
  TodoStatusPicker(selectedStatus: .constant(.todo)) {}
    .padding()
    .background(Color.blue)
}
