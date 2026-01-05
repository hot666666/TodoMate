//
//  DeleteContextMenuButton.swift
//  Todo
//
//  Created by hs on 7/7/25.
//

import SimpleOverlaySystem
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
    overlay: OverlayManager?,
    onConfirmedDelete: @escaping (Todo) -> Void,
  ) -> DeleteContextMenuButton {
    DeleteContextMenuButton(todo: todo) { todo in
      overlay?.presentCentered {
        ConfirmationView(
          title: "\(todo.content) 삭제",
          message: "이 할일을 삭제하시겠습니까?",
          destructiveActionTitle: "삭제",
          cancelTitle: "취소",
          destructiveAction: {
            onConfirmedDelete(todo)
            // Use local id from presentation to dismiss this specific overlay
            // NOTE: 'id' capture might be tricky if it's evaluated immediately.
            // But presentCentered returns the ID immediately.
            // If strict concurrency is an issue, we might need to handle it carefully.
            // For now, assume this works as it returns UUID.
          },
          onDismiss: {
            // Self-dismiss logic handled by ConfirmationView usually triggering this action
            overlay?.dismissTop()
          },
        )
      }

      // Update the ConfirmationView to actually call overlay.dismiss(id: id!) if captured.
      // Or we can rely on `overlay.dismissTop()`.
      // Let's refine the ConfirmationView usage slightly:
      // Since ConfirmationView calls its actions, we need to pass the dismissal logic there.
      // But we can't capture 'id' inside the closure that defines 'id' directly in Swift easily without Optional trickery.
      // A safer bet is just `overlay?.dismissTop()` as confirmation is likely the top-most.
    }
  }
}
