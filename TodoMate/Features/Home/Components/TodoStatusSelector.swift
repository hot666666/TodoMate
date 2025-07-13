//
//  TodoStatusSelector.swift
//  Todo
//
//  Created by hs on 7/7/25.
//

import SwiftUI

struct TodoStatusSelector: View {
  @Binding var selectedStatus: TodoStatus
  let isInteractive: Bool

  @State private var showMenu = false

  var body: some View {
    TodoStatusChip(
      status: selectedStatus,
      action: isInteractive ? { showMenu.toggle() } : nil
    )
    .popover(isPresented: $showMenu) {
      if isInteractive {
        statusSelectionMenu
      }
    }
  }

  private var statusSelectionMenu: some View {
    VStack(spacing: HomeDesignSystem.Component.TodoList.statusPopoverSpacing) {
      ForEach(TodoStatus.allCases, id: \.self) { status in
        TodoStatusChip(status: status) {
          selectedStatus = status
          showMenu = false
        }
      }
    }
    .padding(HomeDesignSystem.Component.TodoList.statusPopoverPadding)
  }
}

#Preview {
  VStack(spacing: 20) {
    TodoStatusSelector(
      selectedStatus: .constant(.todo),
      isInteractive: true
    )

    TodoStatusSelector(
      selectedStatus: .constant(.complete),
      isInteractive: false
    )
  }
  .frame(width: 200, height: 200)
}
