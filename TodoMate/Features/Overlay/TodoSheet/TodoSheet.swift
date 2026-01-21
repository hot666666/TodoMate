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

  // MARK: - Subviews

  private var actionBar: some View {
    HStack(alignment: .center) {
      WrappedTodoStatusButton(status: $editableTodo.status)
      WrappedTodoDateButton(date: $editableTodo.date)

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

  // MARK: - Actions

  private func focusContentIfEmpty() {
    if editableTodo.content.isEmpty {
      isContentFocused = true
    }
  }

  private func submit() {
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

  private func dismissWithConfirmation() {
    if editableTodo.isDirty {
      showDiscardConfirmation()
    } else {
      overlay?.dismissTop()
    }
  }

  private func showDiscardConfirmation() {
    let title = editableTodo.isNew ? "작성 중인 내용을 폐기하시겠습니까?" : "변경사항을 폐기하시겠습니까?"
    let message = editableTodo.isNew ? "작성 중인 내용이 사라집니다." : "저장하지 않은 변경사항이 있습니다."

    overlay?.presentCentered(id: OverlayIDs.discardConfirmation, backdropOpacity: 0) {
      ConfirmationView(
        title: title,
        message: message,
        destructiveActionTitle: "폐기",
        cancelTitle: "취소",
        destructiveAction: {
          // ConfirmationView calls onDismiss automatically after this action.
          overlay?.dismissTop()
        },
        onDismiss: {
          overlay?.dismissTop()
        },
      )
    }
  }
}

// MARK: - Subcomponents

private struct WrappedTodoStatusButton: View {
  @Binding var status: TodoStatus
  @Environment(\.overlayManager) private var overlay

  var body: some View {
    AnchoredOverlayButton(
      placement: .bottom(spacing: 4, alignment: .center),
      dismissPolicy: .tap,
      barrier: .blockAll,
      backdropOpacity: 0,
    ) {
      TodoStatusChip(status: status)
    } content: {
      TodoStatusPicker(
        selectedStatus: $status,
        onDismiss: { overlay?.dismissTop() },
      )
    }
    .buttonStyle(.plain)
  }
}

private struct WrappedTodoDateButton: View {
  @Binding var date: Date
  @Environment(\.overlayManager) private var overlay

  private var isToday: Bool {
    date.isToday
  }

  private var displayText: String {
    isToday ? "오늘" : date.yearMonthDay
  }

  var body: some View {
    AnchoredOverlayButton(
      placement: .bottom(spacing: 4, alignment: .leading),
      dismissPolicy: .tap,
      barrier: .blockAll,
      backdropOpacity: 0,
    ) {
      ChipLabel(
        icon: isToday ? "calendar" : "calendar.badge.clock",
        text: displayText,
        isActive: isToday,
        color: .green,
      )
    } content: {
      TodoDatePicker(
        date: $date,
        onDismiss: { overlay?.dismissTop() },
      )
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  TodoSheet(editableTodo: EditableTodo(owner: "local_user"))
    .environment(TodoBoardStore.preview)
    .frame(width: 600, height: 400)
}
