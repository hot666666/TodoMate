//
//  GroupUserTodoCard.swift
//  TodoMate
//
//  Created by hs on 8/23/25.
//

import SwiftUI

struct GroupUserTodoCard: View {
  let user: User
  let todos: [Todo]

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(user.displayName)
        .font(.callout)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)

      todoList

      Spacer()
    }
    .padding(12)
    .frame(maxWidth: .infinity)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(.tertiary.opacity(0.3), lineWidth: 0.5),
    )
  }

  @ViewBuilder
  private var todoList: some View {
    VStack(alignment: .leading, spacing: 4) {
      if todos.isEmpty {
        emptyState
      } else {
        ForEach(todos) { todo in
          TodoRow(todo: todo)
        }
      }
    }
    .padding(.leading, 3)
  }

  private var emptyState: some View {
    HStack {
      Label("미등록", systemImage: "tray")
        .font(.caption)
    }
    .foregroundStyle(.tertiary)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct TodoRow: View {
  let todo: Todo

  var body: some View {
    HStack(alignment: .center, spacing: 6) {
      Circle()
        .fill(todo.status.color)
        .frame(width: 8, height: 8)

      Text(todo.contentOrPlaceholder)
        .font(.caption)
        .lineLimit(1)
        .foregroundStyle(.primary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

#Preview {
  GroupUserTodoCard(
    user: User(id: "user1", displayName: "테스트 사용자", groupId: "group1"),
    todos: [
      Todo(owner: "user1", content: "할일 1"),
      Todo(owner: "user1", content: "할일 2"),
    ],
  )
  .frame(width: 200, height: 150)
}
