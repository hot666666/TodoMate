//
//  SharedTodoRow.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SwiftUI

struct SharedTodoRow: View {
  let todo: ViewTodo

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: iconName)
        .font(.system(size: 20))
        .foregroundStyle(iconColor)

      VStack(alignment: .leading, spacing: 4) {
        Text(todo.content)
          .foregroundStyle(todo.status == .done ? .secondary : .primary)
          .strikethrough(todo.status == .done)
          .lineLimit(1)

        if !todo.tags.isEmpty {
          HStack {
            ForEach(todo.tags, id: \.self) { tag in
              Text(tag)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(tagColor(for: tag).opacity(0.1))
                .foregroundStyle(tagColor(for: tag))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                  RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(tagColor(for: tag).opacity(0.2)),
                )
            }
          }
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
  }

  private var iconName: String {
    switch todo.status {
    case .done: "checkmark.circle.fill"
    case .inProgress: "circle.inset.filled"
    case .inComplete: "xmark.circle.fill"
    case .todo: "circle"
    }
  }

  private var iconColor: Color {
    switch todo.status {
    case .done: .blue
    case .inProgress: .blue
    case .inComplete: .red
    case .todo: .gray.opacity(0.3)
    }
  }

  func tagColor(for tag: String) -> Color {
    switch tag.lowercased() {
    case "high": .red
    case "system": .purple
    default: .blue
    }
  }
}

#Preview {
  VStack {
    SharedTodoRow(
      todo: ViewTodo(
        owner: "user1",
        content: "Sample Task",
        status: .todo,
        tags: ["High"],
      ))
    SharedTodoRow(
      todo: ViewTodo(
        owner: "user1",
        content: "Completed Task",
        status: .done,
        tags: ["System"],
      ))
    SharedTodoRow(
      todo: ViewTodo(
        owner: "user1",
        content: "In Progress Task",
        status: .inProgress,
        tags: [],
      ))
  }
}
