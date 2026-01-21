//
//  TodoStatusButton.swift
//  Todo
//
//  Created by hs on 6/29/25.
//

import SimpleOverlaySystem
import SwiftUI
import TodoMateDomain

// MARK: - TodoStatusButton

struct TodoStatusButton: View {
  @Environment(\.overlayManager) private var overlay
  @Binding var status: TodoStatus

  var body: some View {
    AnchoredOverlayButton(
      placement: .bottom(spacing: 4, alignment: .center),
      dismissPolicy: .tap,
      barrier: .blockAll,
      backdropOpacity: 0,
    ) {
      TodoStatusChip(status: status)
    } content: {
      TodoStatusPicker(
        selectedStatus: status,
        onSelect: { newStatus in
          status = newStatus
          overlay?.dismissTop()
        },
      )
      .onKeyPress(.escape) {
        overlay?.dismissTop()
        return .handled
      }
    }
    .buttonStyle(.plain)
  }
}

// MARK: - TodoStatusPicker

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
