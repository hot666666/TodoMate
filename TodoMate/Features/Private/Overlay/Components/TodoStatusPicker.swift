//
//  TodoStatusPicker.swift
//  TodoMate
//
//  Created by hs on 11/14/24.
//

import SwiftUI

struct TodoStatusPicker: View {
  let selectedStatus: TodoStatus
  let onSelect: (TodoStatus) -> Void

  var body: some View {
    VStack(spacing: 8) {
      ForEach(filteredStatuses, id: \.self) { status in
        TodoStatusChip(
          status: status,
          action: { onSelect(status) },
          isExpanded: true,
        )
      }
    }
    .padding(8)
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }

  private var filteredStatuses: [TodoStatus] {
    TodoStatus.allCases.filter { $0 != selectedStatus }
  }
}

#Preview {
  TodoStatusPicker(selectedStatus: .todo) { _ in }
    .padding()
    .background(Color.blue)
}
