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
  @Environment(\.overlayManager) private var overlay
  @Environment(TodoBoardStore.self) private var todoStore
  @Environment(CoreDIContainer.self) private var diContainer

  let date: Date
  let onTapTodo: (Todo) -> Void

  @State private var todos: [Todo] = []

  var body: some View {
    DayTodoContent(
      date: date,
      todos: todos.map { ViewTodo(from: $0) },
      onTapTodo: { viewTodo in
        if let todo = todos.first(where: { $0.id == viewTodo.id }) {
          onTapTodo(todo)
        }
      },
      onStatusChange: updateStatus,
      onDuplicateTask: duplicateTask,
      onDeleteTask: deleteTask,
    )
    .padding(20)
    .frame(width: 700, height: 400)
    .background(.regularMaterial)
    .clipShape(.rect(cornerRadius: 12))
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color.gray.opacity(0.3), lineWidth: 1),
    )
    .shadow(color: .black.opacity(0.2), radius: 10)
    .onKeyPress(.escape) {
      overlay?.dismissTop()
      return .handled
    }
    .task(id: date) {
      // Create a 1-day range
      let calendar = Calendar.current
      let startOfDay = calendar.startOfDay(for: date)
      let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
      // -1 sec? or < endOfDay?
      // Range is ClosedRange. So date <= endOfDay.
      // Day is start...start+24h.
      // If endOfDay is next day 00:00:00.
      // date <= endOfDay will include next day's 00:00:00.
      // Typically we want < endOfDay.
      // But ClosedRange requires <=.
      // Use date(byAdding: .second, value: -1, to: endOfDay).
      let endOfRange = calendar.date(byAdding: .second, value: -1, to: endOfDay)!
      let range = startOfDay ... endOfRange

      for await newTodos in diContainer.observeTodosUseCase.execute(dateRange: range) {
        todos = newTodos
      }
    }
  }

  private func updateStatus(_ task: ViewTodo, _ status: ViewTodoStatus) {
    guard let todo = findDomainTodo(for: task) else { return }
    todoStore.updateStatus(todo, status: status.toDomainStatus())
  }

  private func duplicateTask(_ task: ViewTodo) {
    guard let todo = findDomainTodo(for: task) else { return }
    var newTodo = Todo.copy(from: todo)
    newTodo.detail = ""
    todoStore.addTodo(newTodo)
  }

  private func deleteTask(_ task: ViewTodo) {
    guard let todo = findDomainTodo(for: task) else { return }
    todoStore.deleteTodo(todo)
  }

  private func findDomainTodo(for viewTodo: ViewTodo) -> Todo? {
    todos.first(where: { $0.id == viewTodo.id })
  }
}

// MARK: - Content

private struct DayTodoContent: View {
  let date: Date
  let todos: [ViewTodo]
  let onTapTodo: (ViewTodo) -> Void
  let onStatusChange: (ViewTodo, ViewTodoStatus) -> Void
  let onDuplicateTask: (ViewTodo) -> Void
  let onDeleteTask: (ViewTodo) -> Void

  private var title: String {
    date.formatted(.dateTime.month().day().weekday(.wide))
  }

  // Filtered Tasks
  private var todoTasks: [ViewTodo] { todos.filter { $0.status == .todo } }
  private var inProgressTasks: [ViewTodo] { todos.filter { $0.status == .inProgress } }
  private var doneTasks: [ViewTodo] { todos.filter { $0.status == .done } }
  private var incompleteTasks: [ViewTodo] { todos.filter { $0.status == .inComplete } }

  // State for status update (if needed locally or via store access which DayTodoQueryWrapper handles implicitly via ViewTodo update? No, wrapper handles structural changes. Status change context menu in TaskCard handles it via its own binding or callback? TaskCard receives onStatusChange.
  // Wait, TaskCard in DayTodoList calls onTapTodo. It DOES NOT handle status change currently in this file.
  // The TaskCard in BoardView receives onStatusChange.
  // In DayTodoList, we just show them.
  // But context menu allows status change.
  // TaskCard context menu calls `updateStatus`.
  // TaskCard needs `onStatusChange` to be functional for menu.
  // `DayTodoList` does NOT act as a full board.
  // However, if we add Context Menu to change status, we need to handle it.
  // `TaskCard.swift` calls `onStatusChange` when menu item is selected.
  // So I need to implement `onStatusChange` here too!
  // `DayTodoQueryWrapper` lacks `onStatusChange` handling.
  // I should add `onStatusChange` to support context menu fully.

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Header with date and count
      HStack {
        Text(title)
          .font(.title2)
          .bold()

        Text("\(todos.count)")
          .font(.caption)
          .padding(.horizontal, 8)
          .padding(.vertical, 2)
          .background(Color.secondary.opacity(0.2))
          .clipShape(.capsule)

        Spacer()
      }

      if todos.isEmpty {
        Text("이 날짜에 등록된 일정이 없습니다.")
          .font(.caption)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      } else {
        // Column headers (sticky)
        HStack(alignment: .top, spacing: 12) {
          columnHeader("To Do", color: .gray, count: todoTasks.count)
          columnHeader(
            "In Progress", color: DesignSystem.Colors.accentCyan, count: inProgressTasks.count,
          )
          columnHeader("Done", color: DesignSystem.Colors.accentGreen, count: doneTasks.count)
          columnHeader(
            "Incomplete", color: DesignSystem.Colors.accentRed, count: incompleteTasks.count,
          )
        }

        // Scrollable task cards
        ScrollView(.vertical) {
          HStack(alignment: .top, spacing: 12) {
            taskColumn(tasks: todoTasks)
            taskColumn(tasks: inProgressTasks)
            taskColumn(tasks: doneTasks)
            taskColumn(tasks: incompleteTasks)
          }
        }
        .scrollIndicators(.hidden)
      }
    }
  }

  // MARK: - Helper Views

  private func columnHeader(_ title: String, color: Color, count: Int) -> some View {
    HStack(spacing: 6) {
      Circle()
        .fill(color)
        .frame(width: 8, height: 8)

      Text(title)
        .font(.caption)
        .fontWeight(.semibold)

      Text("\(count)")
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func taskColumn(tasks: [ViewTodo]) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      ForEach(tasks) { task in
        TaskCard(
          task: task,
          style: .compact,
          onStatusChange: { status in onStatusChange(task, status) },
          onDuplicate: { onDuplicateTask(task) },
          onDelete: { onDeleteTask(task) },
        )
        .onTapGesture {
          onTapTodo(task)
        }
      }
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

#Preview {
  DayTodoList(
    date: Date(),
    onTapTodo: { _ in },
  )
  .environment(TodoBoardStore.preview)
  .environment(CoreDIContainer.preview)
  .environment(OverlayManager())
  .padding()
}
