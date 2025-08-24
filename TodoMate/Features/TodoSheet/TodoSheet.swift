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

      // popover가 열려있다면 먼저 popover를 닫고, 없다면 submit 수행
      if overlayManager.overlays.last?.type == .popover {
        overlayManager.pop()
        return
      }

      if editableTodo.isDirty {
        let updatedTodo = Todo.from(editableTodo)
        try? container.updateTodoUseCase.run(for: sessionStore.userId, updatedTodo)
      }
      overlayManager.pop()

    case .dismissWithConfirmation:
      // popover가 열려있다면 먼저 popover를 닫고, 없다면 confirmation 수행
      if overlayManager.overlays.last?.type == .popover {
        overlayManager.pop()
      } else {
        overlayManager.popWithConfirmation()
      }
    }
  }
}

extension TodoSheet {
  var body: some View {
    VStack(spacing: TodoSheetDesignSystem.Spacing.small) {
      TodoContentTextField(
        content: $editableTodo.content,
        focusedField: $focusedField,
        onSubmit: { perform(.submitAndDismiss) }
      )
      TodoDetailTextEditor(
        detail: $editableTodo.detail,
        onSubmit: { perform(.submitAndDismiss) }
      )
      HStack(alignment: .center) {
        TodoStatusButton(
          status: $editableTodo.status
        )
        TodoDateButton(
          date: $editableTodo.date
        )
        Spacer()

        Button(editableTodo.isNew ? "생성" : "수정") {
          perform(.submitAndDismiss)
        }
        .buttonStyle(GlassmorphismButtonStyle(disabled: isSubmitDisabled))
        .opacity(isEditable ? 1 : 0)
        .disabled(isSubmitDisabled)
      }
      .padding(.top, TodoSheetDesignSystem.Padding.medium)
    }
    .disabled(!isEditable)
    .onAppear {
      perform(.focusContentField)
    }
    .compositingGroup()
    .onKeyPress(keyCode: 53) {
      perform(.dismissWithConfirmation)
    }
    .padding(TodoSheetDesignSystem.Layout.sheetPadding)
    .frame(maxWidth: TodoSheetDesignSystem.Layout.maxWidth)
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
    .environment(OverlayManager())
    .environment(DIContainer.preview)
    .environment(SessionStore.preview)
    .frame(width: 400, height: 300)
}
