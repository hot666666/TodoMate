//
//  DeleteContextMenuButton.swift
//  Todo
//
//  Created by hs on 7/7/25.
//

import SwiftUI

struct DeleteContextMenuButton: View {
  let todo: Todo
  let onDelete: (Todo) -> Void

  var body: some View {
    Button("삭제", role: .destructive) {
      onDelete(todo)
    }
  }
}

extension DeleteContextMenuButton {
  static func withConfirmation(
    todo: Todo,
    overlayManager: OverlayManager,
    onConfirmedDelete: @escaping (Todo) -> Void,
  ) -> DeleteContextMenuButton {
    DeleteContextMenuButton(todo: todo) { todo in
      overlayManager.presentConfirmation(
        title: "\(todo.content) 삭제",
        message: "이 할일을 삭제하시겠습니까?",
        destructiveActionTitle: "삭제",
      ) {
        onConfirmedDelete(todo)
      }
    }
  }
}
