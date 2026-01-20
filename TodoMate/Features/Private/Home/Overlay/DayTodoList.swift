//
//  DayTodoList.swift
//  TodoMate
//
//  Created by agent on 1/7/26.
//
//

import SimpleOverlaySystem
import SwiftData
import SwiftUI
import TodoMateDomain

/// 특정 날짜의 모든 할 일 목록을 4열 상태별 레이아웃으로 보여주는 오버레이 뷰
struct DayTodoList: View {
  // MARK: - Properties

  @Environment(\.overlayManager) private var overlay

  let date: Date
  let viewModel: TodoCalendarViewModel

  let onTapTodo: (Todo) -> Void

  // MARK: - Body

  var body: some View {
    DayTodoContent(
      date: date,
      todos: viewModel.todos(for: date),
      onTapTodo: onTapTodo,
      onStatusChange: { todo, newStatus in
        var updated = todo
        updated.status = newStatus
        viewModel.update(updated)
      },
      onDeleteTask: { todo in
        viewModel.delete(todo)
      },
      onDuplicateTask: { _ in }, // Placeholder
    )
    .padding(20)
    .frame(width: 900, height: 500)
    .background(.regularMaterial)
    .clipShape(.rect(cornerRadius: 16))
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(Color.gray.opacity(0.2), lineWidth: 1),
    )
    .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 4)
    .onKeyPress(.escape) {
      overlay?.dismissTop()
      return .handled
    }
  }
}

// MARK: - Content

private struct DayTodoContent: View {
  // MARK: - Properties

  let date: Date
  let todos: [Todo]
  let onTapTodo: (Todo) -> Void
  let onStatusChange: (Todo, TodoStatus) -> Void
  let onDeleteTask: (Todo) -> Void
  let onDuplicateTask: (Todo) -> Void

  // MARK: - Computed Properties

  private var title: String {
    date.formatted(.dateTime.month().day().weekday(.wide))
  }

  // Tasks count for badge
  private var totalCount: Int { todos.count }

  // MARK: - Body

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      // Header with date and count
      HStack {
        Text(title)
          .font(.title2)
          .bold()

        Text("\(totalCount)")
          .font(.caption)
          .padding(.horizontal, 8)
          .padding(.vertical, 2)
          .background(Color.secondary.opacity(0.2))
          .clipShape(.capsule)

        Spacer()

        Button {
          // Close action handled by generic overlay dismiss usually,
          // but could add explicit close here if needed.
        } label: {
          Image(systemName: "xmark.circle.fill")
            .font(.title3)
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .opacity(0) // Keep layout but hidden as escape works
      }

      if todos.isEmpty {
        Text("이 날짜에 등록된 일정이 없습니다.")
          .font(.body)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      } else {
        // Columns using reusable TaskColumnView
        HStack(alignment: .top, spacing: 16) {
          ForEach(TodoStatus.allCases, id: \.self) { status in
            makeColumn(status: status, tasks: todos.filter { $0.status == status })
          }
        }
      }
    }
  }

  // MARK: - Helper Views

  @discardableResult
  private func handleDrop(_ items: [Todo], to status: TodoStatus) -> Bool {
    guard let todo = items.first else { return false }
    if todo.status != status {
      onStatusChange(todo, status)
    }
    return true
  }

  private func makeColumn(status: TodoStatus, tasks: [Todo]) -> some View {
    TaskColumnView(title: status.displayName, count: tasks.count, color: status.displayColor) {
      ScrollView(.vertical, showsIndicators: false) {
        LazyVStack(spacing: 2) {
          ForEach(tasks) { task in
            TodoCard(
              style: .compact,
              todo: task,
              onStatusChange: { status in
                onStatusChange(task, status)
              },
              onDuplicate: { onDuplicateTask(task) },
              onDelete: { onDeleteTask(task) },
            )
            .draggable(task)
            .onTapGesture {
              onTapTodo(task)
            }
          }
        }
        .padding(2)
      }
      .contentMargins(.bottom, 16, for: .scrollContent)
    }
    .frame(maxWidth: .infinity)
    .dropDestination(for: Todo.self) { items, _ in
      handleDrop(items, to: status)
    }
  }
}

#Preview {
  DayTodoList(
    date: Date(),
    viewModel: TodoCalendarViewModel.preview,
    onTapTodo: { _ in },
  )
  .environment(OverlayManager())
  .padding()
}
