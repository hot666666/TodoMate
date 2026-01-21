//
//  TodoContextMenuModifier.swift
//  TodoMate
//
//  Created by hs on 1/21/26.
//

import SwiftUI
import TodoMateDomain

// MARK: - TodoContextMenu

struct TodoContextMenuModifier: ViewModifier {
  let todo: Todo
  let onStatusChange: (TodoStatus) -> Void
  let onDuplicate: () -> Void
  let onDelete: () -> Void

  func body(content: Content) -> some View {
    content.contextMenu {
      Menu {
        ForEach(TodoStatus.allCases, id: \.self) { status in
          if status != todo.status {
            Button {
              onStatusChange(status)
            } label: {
              Label(status.displayName, systemImage: status.iconName)
            }
          }
        }
      } label: {
        Label("Change Status", systemImage: "arrow.triangle.2.circlepath")
      }

      Divider()

      Button {
        onDuplicate()
      } label: {
        Label("Duplicate", systemImage: "plus.square.on.square")
      }

      Button(role: .destructive) {
        onDelete()
      } label: {
        Label("Delete", systemImage: "trash")
      }
    }
  }
}

extension View {
  func todoContextMenu(
    todo: Todo,
    onStatusChange: @escaping (TodoStatus) -> Void,
    onDuplicate: @escaping () -> Void,
    onDelete: @escaping () -> Void,
  ) -> some View {
    modifier(
      TodoContextMenuModifier(
        todo: todo,
        onStatusChange: onStatusChange,
        onDuplicate: onDuplicate,
        onDelete: onDelete,
      ),
    )
  }
}
