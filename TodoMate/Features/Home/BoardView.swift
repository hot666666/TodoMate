//
//  BoardView.swift
//  TodoMate
//
//  Kanban-style board view for tasks
//
//  Created by agent on 1/5/26.
//

import SimpleOverlaySystem
import SwiftUI

struct BoardView: View {
  @Environment(TodoStore.self) private var todoStore
  @Environment(SessionStore.self) private var sessionStore
  @Environment(\.overlayManager) private var overlay
  let selection: NavigationDestination

  // Computed properties to group tasks by status
  private var viewTodos: [ViewTodo] {
    let todos = todoStore.todos[sessionStore.userId] ?? []
    return todos.map { ViewTodo(from: $0) }
  }

  private var todoTasks: [ViewTodo] {
    viewTodos.filter { $0.status == .todo }
  }

  private var inProgressTasks: [ViewTodo] {
    viewTodos.filter { $0.status == .inProgress }
  }

  private var doneTasks: [ViewTodo] {
    viewTodos.filter { $0.status == .done }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Date Header
      Text(Date().formatted(.dateTime.year().month().day().weekday(.wide)))
        .font(.title2)
        .fontWeight(.semibold)
        .padding(.horizontal)

      // Simple HStack - each column takes equal width via frame(maxWidth: .infinity)
      HStack(alignment: .top, spacing: 16) {
        TodoColumn(
          title: "To Do",
          count: todoTasks.count,
          color: .gray,
          tasks: todoTasks,
          onTapTask: presentTodoSheet,
          onDropTask: { task in updateTaskStatus(task, to: .todo) },
        )
        .frame(maxWidth: .infinity)

        TodoColumn(
          title: "In Progress",
          count: inProgressTasks.count,
          color: DesignSystem.Colors.accentCyan,
          tasks: inProgressTasks,
          onTapTask: presentTodoSheet,
          onDropTask: { task in updateTaskStatus(task, to: .inProgress) },
        )
        .frame(maxWidth: .infinity)

        TodoColumn(
          title: "Done",
          count: doneTasks.count,
          color: DesignSystem.Colors.accentGreen,
          tasks: doneTasks,
          onTapTask: presentTodoSheet,
          onDropTask: { task in updateTaskStatus(task, to: .done) },
        )
        .frame(maxWidth: .infinity)
      }
      .padding(.horizontal)
    }
    .padding(.top)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(Color(nsColor: .windowBackgroundColor))
    .accessibilityIdentifier("personalBoardView")
  }

  // MARK: - Actions

  private func presentTodoSheet(for task: ViewTodo) {
    guard let userTodos = todoStore.todos[sessionStore.userId],
          let originalTodo = userTodos.first(where: { $0.id == task.id })
    else { return }

    let editableTodo = EditableTodo(from: originalTodo)
    overlay?.presentCentered {
      TodoSheet(editableTodo: editableTodo)
    }
  }

  private func updateTaskStatus(_ task: ViewTodo, to newStatus: ViewTodoStatus) {
    guard let userTodos = todoStore.todos[sessionStore.userId],
          let originalTodo = userTodos.first(where: { $0.id == task.id })
    else { return }

    var updatedTodo = originalTodo
    updatedTodo.status = newStatus.toDomainStatus()
    updatedTodo.updatedAt = Date()

    todoStore.update(updatedTodo, userId: sessionStore.userId)
  }
}

// MARK: - Todo Column

private struct TodoColumn: View {
  let title: String
  let count: Int
  let color: Color
  let tasks: [ViewTodo]
  let onTapTask: (ViewTodo) -> Void
  let onDropTask: (ViewTodo) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      columnHeader

      // Vertical scroll for cards within this column
      ScrollView(.vertical) {
        LazyVStack(spacing: 12) {
          ForEach(tasks) { task in
            TaskCard(task: task)
              .draggable(task)
              .onTapGesture {
                onTapTask(task)
              }
          }
        }
      }
      .scrollIndicators(.hidden)
    }
    .dropDestination(for: ViewTodo.self) { items, _ in
      if let task = items.first {
        onDropTask(task)
        return true
      }
      return false
    }
  }

  private var columnHeader: some View {
    HStack {
      Circle()
        .fill(color)
        .frame(width: 10, height: 10)

      Text(title)
        .font(.headline)

      Text("\(count)")
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Color.secondary.opacity(0.1))
        .clipShape(.capsule)

      Spacer()
    }
  }
}

#Preview {
  BoardView(selection: .todo)
    .environment(TodoStore.preview)
    .environment(SessionStore.preview)
    .environment(OverlayManager())
}
