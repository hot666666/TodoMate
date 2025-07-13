//
//  TodoSheet.swift
//  Todo
//
//  Created by hs on 6/7/25.
//

import SwiftUI

struct TodoSheet: View {
  @Environment(DIContainer.self) private var container
  @Environment(SessionStore.self) private var sessionStore
  @Environment(OverlayManager.self) private var overlayManager
  @FocusState private var focusedField: Field?
  enum Field: Hashable {
    case content
  }

  @Bindable var editableTodo: EditableTodo

  private func focusContentField() {
    if isEditable, editableTodo.content.isEmpty {
      focusedField = .content
    }
  }

  private var isEditable: Bool {
    sessionStore.userId == editableTodo.owner
  }

  private var isSubmitDisabled: Bool {
    !isEditable || editableTodo.content.isEmpty || !editableTodo.isDirty
  }

  private func submitAndDismiss() {
    guard isEditable else { return }

    if editableTodo.isDirty {
      let updatedTodo = Todo.from(editableTodo)
      try? container.updateTodoUseCase.run(for: sessionStore.userId, updatedTodo)
    }

    overlayManager.pop()
  }
}

extension TodoSheet {
  var body: some View {
    VStack(spacing: TodoSheetDesignSystem.Spacing.small) {
      TodoContentTextField(
        content: $editableTodo.content,
        focusedField: $focusedField,
        onSubmit: submitAndDismiss
      )
      TodoDetailTextEditor(
        detail: $editableTodo.detail,
        onSubmit: submitAndDismiss
      )
      HStack(alignment: .center) {
        TodoStatusButton(
          status: $editableTodo.status,
        )
        TodoDateButton(
          date: $editableTodo.date,
        )
        Spacer()

        Button(editableTodo.isNew ? "생성" : "수정") {
          submitAndDismiss()
        }
        .opacity(isEditable ? 1 : 0)
        .disabled(isSubmitDisabled)
      }
      .padding(.top, TodoSheetDesignSystem.Padding.medium)
    }
    .disabled(!isEditable)
    .onAppear {
      focusContentField()
    }
    .compositingGroup()
    .onKeyPress(keyCode: 53) {
      overlayManager.pop()
    }
    .padding(TodoSheetDesignSystem.Layout.sheetPadding)
    .frame(maxWidth: TodoSheetDesignSystem.Layout.maxWidth)
    .coordinateSpace(name: "TodoSheet")
  }
}

#Preview {
  TodoSheet(editableTodo: EditableTodo(owner: SessionStore.preview.userId))
    .environment(OverlayManager())
    .environment(DIContainer.preview)
    .environment(SessionStore.preview)
    .frame(width: 400, height: 300)
}
