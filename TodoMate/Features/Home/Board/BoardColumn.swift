//
//  BoardColumn.swift
//  TodoMate
//
//  Created by hs on 1/21/26.
//

import SwiftUI
import TodoMateDomain

struct BoardColumn: View {
  // MARK: - Properties

  let status: TodoStatus
  let todos: [Todo]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      columnHeader
      todoList
    }
  }

  private var columnHeader: some View {
    HStack(spacing: 8) {
      Image(systemName: status.iconName)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(status.displayColor)

      Text(status.displayName)
        .font(.headline)
        .foregroundStyle(.primary)

      Text("\(todos.count)")
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(Capsule())

      Spacer()
    }
    .padding(.horizontal, 4)
  }

  private var todoList: some View {
    ScrollView(.vertical, showsIndicators: false) {
      LazyVStack(spacing: 12) {
        ForEach(todos) { todo in
          BoardTodoCard(todo: todo)
            .draggable(todo)
            .opacity(todo.date.isToday ? 1.0 : 0.6)
        }
      }
    }
    .contentMargins(.bottom, 20, for: .scrollContent)
  }
}
