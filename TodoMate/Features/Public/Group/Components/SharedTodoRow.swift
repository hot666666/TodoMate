//
//  SharedTodoRow.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SwiftUI

import TodoMateDomain

struct SharedTodoRow: View {
  let todo: Todo

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: todo.status.iconName)
        .font(.system(size: 20))
        .foregroundStyle(todo.status.displayColor)

      VStack(alignment: .leading, spacing: 4) {
        Text(todo.content)
          .foregroundStyle(todo.status == .complete ? .secondary : .primary)
          .strikethrough(todo.status == .complete)
          .lineLimit(1)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
  }
}

#Preview {
  VStack {
    SharedTodoRow(
      todo: Todo(
        content: "Sample Task",
        status: .todo,
        detail: "",
        date: .now,
        createdAt: .now,
        updatedAt: .now,
        owner: "user1",
        isDeleted: false,
      ))
    SharedTodoRow(
      todo: Todo(
        content: "Completed Task",
        status: .complete,
        detail: "",
        date: .now,
        createdAt: .now,
        updatedAt: .now,
        owner: "user1",
        isDeleted: false,
      ))
    SharedTodoRow(
      todo: Todo(
        content: "In Progress Task",
        status: .inProgress,
        detail: "",
        date: .now,
        createdAt: .now,
        updatedAt: .now,
        owner: "user1",
        isDeleted: false,
      ))
  }
}
