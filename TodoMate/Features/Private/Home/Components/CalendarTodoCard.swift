//
//  CalendarTodoCard.swift
//  TodoMate
//
//  Created by agent on 1/19/26.
//

import SwiftUI
import TodoMateDomain

struct CalendarTodoCard: View {
  let todo: Todo

  var body: some View {
    HStack(alignment: .center, spacing: 0) {
      // Left color strip
      Rectangle()
        .fill(todo.status.displayColor)
        .frame(width: 3)

      Text(todo.content)
        .font(.caption2.weight(.medium))
        .foregroundStyle(todo.status == .complete ? .secondary : .primary)
        .strikethrough(todo.status == .complete)
        .lineLimit(1)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)

      Spacer(minLength: 0)
    }
    .frame(height: 24)
    .background(todo.status.displayColor.opacity(0.1))
    .clipShape(.rect(cornerRadius: 4))
    .overlay(
      RoundedRectangle(cornerRadius: 4)
        .strokeBorder(todo.status.displayColor.opacity(0.3), lineWidth: 0.5),
    )
  }
}

#Preview {
  CalendarTodoCard(todo: Todo.stub)
}
