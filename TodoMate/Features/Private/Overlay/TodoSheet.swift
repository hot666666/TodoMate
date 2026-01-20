//
//  TodoSheet.swift
//  Todo
//
//  Created by hs on 6/7/25.
//
//

import SimpleOverlaySystem
import SwiftUI
import TodoMateDomain

struct TodoSheet: View {
  // MARK: - Properties

  @Environment(TodoBoardStore.self) private var todoStore
  @Environment(\.overlayManager) private var overlay

  @State private var editableTodo: EditableTodo
  @FocusState private var focusedField: SheetField?

  // MARK: - Types

  enum Action {
    case focusContentField
    case submitAndDismiss
    case dismissWithConfirmation
  }

  enum SheetField: Hashable {
    case content
  }

  // MARK: - Init

  init(editableTodo: EditableTodo) {
    _editableTodo = State(initialValue: editableTodo)
  }

  // MARK: - Computed Properties

  private var isSubmitDisabled: Bool {
    editableTodo.content.isEmpty || !editableTodo.isDirty
  }

  // MARK: - Body

  var body: some View {
    @Bindable var todo = editableTodo

    VStack(spacing: DesignSystem.TodoSheet.Spacing.small) {
      TodoContentTextField(
        content: $todo.content,
        focusedField: $focusedField,
        onSubmit: { perform(.submitAndDismiss) },
      )
      TodoDetailTextEditor(
        detail: $todo.detail,
        onSubmit: { perform(.submitAndDismiss) },
      )
      HStack(alignment: .center) {
        TodoStatusButton(
          status: $todo.status,
        )
        TodoDateButton(
          date: $todo.date,
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
    .onTapBackground {
      perform(.dismissWithConfirmation)
    }
    .onGlobalHotKey(.escape) {
      Task { @MainActor in
        perform(.dismissWithConfirmation)
      }
    }
    .onAppear {
      perform(.focusContentField)
    }
    .compositingGroup()
    .padding(DesignSystem.TodoSheet.Layout.sheetPadding)
    .frame(width: 450)
    .background(.regularMaterial)
    .clipShape(.rect(cornerRadius: 12))
    .shadow(color: .black.opacity(0.2), radius: 10)
    .coordinateSpace(name: "TodoSheet")
  }
}

// MARK: - Helpers

extension TodoSheet {
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
            overlay?.dismissTop() // Dismiss confirmation
            overlay?.dismissTop() // Dismiss sheet
          },
          onDismiss: {
            overlay?.dismissTop() // Just dismiss confirmation
          },
        )
        overlay?.presentCentered(backdropOpacity: 0) {
          confirmationView
        }
      } else {
        overlay?.dismissTop()
      }
    }
  }
}

#Preview {
  TodoSheet(editableTodo: EditableTodo(owner: "local_user"))
    .environment(TodoBoardStore.preview)
    .frame(width: 600, height: 400)
}
