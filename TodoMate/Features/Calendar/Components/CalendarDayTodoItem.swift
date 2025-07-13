//
//  CalendarDayTodoItem.swift
//  Todo
//
//  Created by hs on 6/29/25.
//

import SwiftUI

struct CalendarDayTodoItem: View {
  let todo: Todo
  let sourceDate: Date

  @State private var dragState: DragState = .inactive

  private var draggedTodo: DraggedTodo {
    DraggedTodo(
      todoId: todo.id,
      sourceDate: sourceDate,
      content: todo.contentOrPlaceholder
    )
  }

  var body: some View {
    HStack(spacing: CalendarDesignSystem.Component.TodoItem.spacing) {
      Text(todo.contentOrPlaceholder)
        .font(CalendarDesignSystem.Component.TodoItem.font)
        .foregroundStyle(.primary)
        .lineLimit(1)
      Spacer(minLength: 0)
    }
    .padding(.horizontal, CalendarDesignSystem.Component.TodoItem.horizontalPadding)
    .padding(.vertical, CalendarDesignSystem.Component.TodoItem.verticalPadding)
    .background(
      RoundedRectangle(cornerRadius: CalendarDesignSystem.Component.TodoItem.cornerRadius)
        .fill(todo.status.color)
    )
    .opacity(dragState == .draggedOut ? CalendarDesignSystem.Animation.dragOpacity : 1.0)
    .scaleEffect(dragState == .dragging ? CalendarDesignSystem.Animation.dragScale : 1.0)
    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragState)
    .draggable(draggedTodo) { dragPreview }
  }

  private var dragPreview: some View {
    HStack(spacing: CalendarDesignSystem.Component.TodoItem.spacing) {
      Text(todo.contentOrPlaceholder)
        .font(CalendarDesignSystem.Component.TodoItem.font)
        .foregroundStyle(.primary)
        .lineLimit(1)
      Spacer(minLength: 0)
    }
    .padding(.horizontal, CalendarDesignSystem.Component.TodoItem.dragPreviewHorizontalPadding)
    .padding(.vertical, CalendarDesignSystem.Component.TodoItem.dragPreviewVerticalPadding)
    .background(
      RoundedRectangle(cornerRadius: CalendarDesignSystem.Component.TodoItem.cornerRadius)
        .fill(todo.status.color.opacity(CalendarDesignSystem.Component.TodoItem.dragPreviewOpacity))
    )
  }
}

extension CalendarDayTodoItem {
  enum DragState {
    case inactive
    case dragging
    case draggedOut
  }
}
