//
//  TodoSheet.swift
//  Todo
//
//  Created by hs on 6/7/25.
//

import SimpleOverlaySystem
import SwiftUI

struct TodoSheet: View {
  @Environment(PrivateTodoStore.self) private var todoStore
  @Environment(\.overlayManager) private var overlay

  @FocusState private var focusedField: SheetField?
  @Bindable var editableTodo: EditableTodo

  private var isSubmitDisabled: Bool {
    editableTodo.content.isEmpty || !editableTodo.isDirty
  }

  enum Action {
    case focusContentField
    case submitAndDismiss
    case dismissWithConfirmation
  }

  private func perform(_ action: Action) {
    switch action {
    case .focusContentField:
      if editableTodo.content.isEmpty {
        focusedField = .content
      }

    case .submitAndDismiss:
      if editableTodo.isDirty {
        let todo = Todo.from(editableTodo)
        if editableTodo.isNew {
          todoStore.addTodo(todo)
        } else {
          todoStore.updateTodo(todo)
        }
      }
      overlay?.dismissTop()

    case .dismissWithConfirmation:
      // Show confirmation if dirty
      if editableTodo.isDirty {
        let title = editableTodo.isNew ? "작성 중인 내용을 폐기하시겠습니까?" : "변경사항을 폐기하시겠습니까?"
        let message = editableTodo.isNew ? "작성 중인 내용이 사라집니다." : "저장하지 않은 변경사항이 있습니다."

        let confirmationView = ConfirmationView(
          title: title,
          message: message,
          destructiveActionTitle: "폐기",
          cancelTitle: "취소",
          destructiveAction: {
            overlay?.dismissTop()
            // Dismiss sheet
            overlay?.dismissTop()
          },
          onDismiss: {
            // Just dismiss confirmation
            overlay?.dismissTop()
          },
        )
        overlay?.presentCentered {
          confirmationView
        }
      } else {
        overlay?.dismissTop()
      }
    }
  }
}

extension TodoSheet {
  var body: some View {
    VStack(spacing: DesignSystem.TodoSheet.Spacing.small) {
      TodoContentTextField(
        content: $editableTodo.content,
        focusedField: $focusedField,
        onSubmit: { perform(.submitAndDismiss) },
      )
      TodoDetailTextEditor(
        detail: $editableTodo.detail,
        onSubmit: { perform(.submitAndDismiss) },
      )
      HStack(alignment: .center) {
        TodoStatusButton(
          status: $editableTodo.status,
        )
        TodoDateButton(
          date: $editableTodo.date,
        )
        Spacer()

        TodoSheetActionButton(
          hasChanges: editableTodo.isDirty,
          isNew: editableTodo.isNew,
          onSave: { perform(.submitAndDismiss) },
          onDismiss: { perform(.dismissWithConfirmation) },
        )
      }
      .padding(.top, DesignSystem.TodoSheet.Padding.medium)
    }
    .onAppear {
      perform(.focusContentField)
    }
    .onTapBackground {
      perform(.dismissWithConfirmation)
    }
    .compositingGroup()
    .padding(DesignSystem.TodoSheet.Layout.sheetPadding)
    .frame(width: 450)
    .background(.regularMaterial)
    .clipShape(.rect(cornerRadius: 12))
    .shadow(color: .black.opacity(0.2), radius: 10)
    .coordinateSpace(name: "TodoSheet")
    .onKeyPress(.escape) {
      perform(.dismissWithConfirmation)
      return .handled
    }
  }
}

extension TodoSheet {
  enum SheetField: Hashable {
    case content
  }
}

#Preview {
  TodoSheet(editableTodo: EditableTodo(owner: "local_user"))
    .environment(PrivateTodoStore.preview)
    .frame(width: 600, height: 400)
}
