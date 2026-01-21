//
//  TodoSheet.swift
//  Todo
//
//  Created by hs on 6/7/25.
//

import SimpleOverlaySystem
import SwiftUI
import TodoMateDomain

// MARK: - TodoSheet

struct TodoSheet: View {
  // MARK: - Environment

  @Environment(TodoBoardStore.self) private var todoStore
  @Environment(\.overlayManager) private var overlay

  // MARK: - State

  @State private var editableTodo: EditableTodo
  @FocusState private var isContentFocused: Bool

  // MARK: - Init

  init(editableTodo: EditableTodo) {
    _editableTodo = State(initialValue: editableTodo)
  }

  // MARK: - Body

  var body: some View {
    @Bindable var todo = editableTodo

    VStack(spacing: DesignSystem.TodoSheet.Spacing.small) {
      TodoContentTextField(
        content: $todo.content,
        isFocused: $isContentFocused,
        onSubmit: submit,
      )
      TodoDetailTextEditor(
        detail: $todo.detail,
        onSubmit: submit,
      )
      actionBar
    }
    .onTapBackground { dismissWithConfirmation() }
    .onGlobalHotKey(.escape) {
      Task { @MainActor in dismissWithConfirmation() }
    }
    .onAppear { focusContentIfEmpty() }
    .compositingGroup()
    .padding(DesignSystem.TodoSheet.Layout.sheetPadding)
    .frame(width: 450)
    .materialCardOverlay()
    .coordinateSpace(name: "TodoSheet")
  }

  private var actionBar: some View {
    HStack(alignment: .center) {
      TodoStatusButton(status: Bindable(editableTodo).status)
      TodoDateButton(date: Bindable(editableTodo).date)
      Spacer()

      TodoSheetActionButton(
        hasChanges: editableTodo.isDirty,
        isNew: editableTodo.isNew,
        onSave: submit,
        onDismiss: dismissWithConfirmation,
      )
    }
    .padding(.top, DesignSystem.TodoSheet.Padding.medium)
  }
}

// MARK: - Actions

private extension TodoSheet {
  func focusContentIfEmpty() {
    if editableTodo.content.isEmpty {
      isContentFocused = true
    }
  }

  func submit() {
    if editableTodo.isDirty {
      let todo = Todo.from(editableTodo)
      if editableTodo.isNew {
        todoStore.addTodo(todo)
      } else {
        todoStore.updateTodo(todo)
      }
    }
    overlay?.dismissTop()
  }

  func dismissWithConfirmation() {
    if editableTodo.isDirty {
      showDiscardConfirmation()
    } else {
      overlay?.dismissTop()
    }
  }

  func showDiscardConfirmation() {
    let title = editableTodo.isNew ? "작성 중인 내용을 폐기하시겠습니까?" : "변경사항을 폐기하시겠습니까?"
    let message = editableTodo.isNew ? "작성 중인 내용이 사라집니다." : "저장하지 않은 변경사항이 있습니다."

    overlay?.presentCentered(backdropOpacity: 0) {
      ConfirmationView(
        title: title,
        message: message,
        destructiveActionTitle: "폐기",
        cancelTitle: "취소",
        destructiveAction: {
          overlay?.dismissTop() // Dismiss confirmation
          overlay?.dismissTop() // Dismiss sheet
        },
        onDismiss: {
          overlay?.dismissTop() // Just dismiss confirmation
        },
      )
    }
  }
}

#Preview {
  TodoSheet(editableTodo: EditableTodo(owner: "local_user"))
    .environment(TodoBoardStore.preview)
    .frame(width: 600, height: 400)
}
