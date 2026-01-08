//
//  TodoSheet.swift
//  Todo
//
//  Created by hs on 6/7/25.
//

import SimpleOverlaySystem
import SwiftUI

struct TodoSheet: View {
  @Environment(DIContainer.self) private var container
  @Environment(TodoStore.self) private var todoStore
  @Environment(SessionStore.self) private var sessionStore
  @Environment(\.overlayManager) private var overlay

  @FocusState private var focusedField: SheetField?
  @Bindable var editableTodo: EditableTodo

  private var isEditable: Bool {
    sessionStore.userId == editableTodo.owner
  }

  private var isSubmitDisabled: Bool {
    !isEditable || editableTodo.content.isEmpty || !editableTodo.isDirty
  }

  enum Action {
    case focusContentField
    case submitAndDismiss
    case dismissWithConfirmation
  }

  private func perform(_ action: Action) {
    switch action {
    case .focusContentField:
      if isEditable, editableTodo.content.isEmpty {
        focusedField = .content
      }

    case .submitAndDismiss:
      guard isEditable else { return }

      if editableTodo.isDirty {
        let todo = Todo.from(editableTodo)
        if editableTodo.isNew {
          todoStore.add(todo, userId: sessionStore.userId)
        } else {
          todoStore.update(todo, userId: sessionStore.userId)
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

        if isEditable {
          TodoSheetActionButton(
            hasChanges: editableTodo.isDirty,
            isNew: editableTodo.isNew,
            onSave: { perform(.submitAndDismiss) },
            onDismiss: { perform(.dismissWithConfirmation) },
          )
        }
      }
      .padding(.top, DesignSystem.TodoSheet.Padding.medium)
    }
    .disabled(!isEditable)
    .onAppear {
      perform(.focusContentField)
    }
    .compositingGroup()
    .onKeyPress(keyCode: 53) {
      perform(.dismissWithConfirmation)
    }
    .padding(DesignSystem.TodoSheet.Layout.sheetPadding)
    .frame(width: 450)
    .background(.regularMaterial)
    .clipShape(.rect(cornerRadius: 12))
    .shadow(color: .black.opacity(0.2), radius: 10)
    .coordinateSpace(name: "TodoSheet")
  }
}

extension TodoSheet {
  enum SheetField: Hashable {
    case content
  }
}

#Preview {
  TodoSheet(editableTodo: EditableTodo(owner: SessionStore.preview.userId))
    .environment(DIContainer.preview)
    .environment(SessionStore.preview)
    .frame(width: 600, height: 400)
}
