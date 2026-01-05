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

  @State private var todoStatus: TodoStatus
  @State private var isHovering: Bool = false

  init(
    todo: Todo,
    isInteractive: Bool = false,
    onTap: @escaping (Todo) -> Void,
    onUpdate: ((Todo) -> Void)? = nil,
  ) {
    self.todo = todo
    self.isInteractive = isInteractive
    self.onTap = onTap
    self.onUpdate = onUpdate
    _todoStatus = State(wrappedValue: todo.status)
  }

  var body: some View {
    HStack(alignment: .center, spacing: HomeDesignSystem.Component.TodoList.itemHorizontalSpacing) {
      statusSelector
      contentSection
    }
    .onChange(of: todo.status) { todoStatus = $1 }
    .onChange(of: todoStatus) { _, newValue in
      guard isInteractive else { return }
      let updatedTodo = todo.withUpdatedStatus(newValue)
      onUpdate?(updatedTodo)
    }
    .onHover { hovering in
      withAnimation(.easeInOut(duration: 0.2)) {
        isHovering = hovering
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(isHovering ? Color.secondary.opacity(0.1) : Color.clear),
    )
  }

  private var statusSelector: some View {
    TodoStatusSelector(
      selectedStatus: $todoStatus,
      isInteractive: isInteractive,
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
    TodoItem(todo: .stub, isInteractive: true, onTap: { _ in })
    TodoItem(todo: .stub, isInteractive: false, onTap: { _ in })
  }
  .frame(width: 400)
}
