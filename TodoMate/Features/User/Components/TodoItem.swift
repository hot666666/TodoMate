//
//  TodoItem.swift
//  Todo
//
//  Created by hs on 6/7/25.
//

import SwiftUI

struct TodoItem: View {
  let todo: Todo
  let isInteractive: Bool
  let onTap: (Todo) -> Void
  let onUpdate: ((Todo) -> Void)?
  let showDragHandle: Bool

  @State private var todoStatus: TodoStatus

  init(
    todo: Todo,
    isInteractive: Bool = false,
    showDragHandle: Bool = false,
    onTap: @escaping (Todo) -> Void,
    onUpdate: ((Todo) -> Void)? = nil
  ) {
    self.todo = todo
    self.isInteractive = isInteractive
    self.showDragHandle = showDragHandle
    self.onTap = onTap
    self.onUpdate = onUpdate
    _todoStatus = State(wrappedValue: todo.status)
  }

  var body: some View {
    HStack(alignment: .center, spacing: HomeDesignSystem.Component.TodoList.itemHorizontalSpacing) {
      dragHandleView
      statusSelector
      contentSection
    }
    .onChange(of: todo.status) { todoStatus = $1 }
    .onChange(of: todoStatus) { _, newValue in
      guard isInteractive else { return }
      let updatedTodo = todo.withUpdatedStatus(newValue)
      onUpdate?(updatedTodo)
    }
    .cardBackground(padding: EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
    .hoverable()
  }

  private var dragHandleView: some View {
    Image(systemName: "line.3.horizontal")
      .foregroundStyle(.secondary)
      .opacity(showDragHandle ? HomeDesignSystem.Component.TodoList.dragHandleOpacity : 0)
      .frame(width: HomeDesignSystem.Component.TodoList.dragHandleWidth)
  }

  private var statusSelector: some View {
    TodoStatusSelector(
      selectedStatus: $todoStatus,
      isInteractive: isInteractive
    )
  }

  private var contentSection: some View {
    HStack {
      Text(todo.contentOrPlaceholder)
        .font(HomeDesignSystem.Component.TodoList.Typography.contentFont)

      Spacer()

      Text(todo.compactDetail)
        .foregroundStyle(.secondary)
        .font(HomeDesignSystem.Component.TodoList.Typography.detailFont)
    }
    .contentShape(.rect)
    .onTapGesture {
      onTap(todo)
    }
  }
}

#Preview {
  VStack {
    TodoItem(todo: .stub, isInteractive: true, showDragHandle: true, onTap: { _ in })
    TodoItem(todo: .stub, isInteractive: false, showDragHandle: false, onTap: { _ in })
  }
  .frame(width: 400)
}
