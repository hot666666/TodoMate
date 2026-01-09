//
//  DayTodoListView.swift
//  TodoMate
//
//  Created by agent on 1/7/26.
//

import SimpleOverlaySystem
import SwiftUI

/// 특정 날짜의 모든 할 일 목록을 4열 상태별 레이아웃으로 보여주는 오버레이 뷰
struct DayTodoListView: View {
  @Environment(\.overlayManager) private var overlay

  let date: Date
  let todos: [ViewTodo]
  let onTapTodo: (ViewTodo) -> Void

  private var title: String {
    date.formatted(.dateTime.month().day().weekday(.wide))
  }

  // MARK: - Filtered Tasks by Status

  private var todoTasks: [ViewTodo] {
    todos.filter { $0.status == .todo }
  }

  private var inProgressTasks: [ViewTodo] {
    todos.filter { $0.status == .inProgress }
  }

  private var doneTasks: [ViewTodo] {
    todos.filter { $0.status == .done }
  }

  private var incompleteTasks: [ViewTodo] {
    todos.filter { $0.status == .inComplete }
  }

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
        TaskCard(task: task, style: .compact)
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
  DayTodoListView(
    date: Date(),
    todos: [
      ViewTodo(
        id: "1", owner: "u", content: "Task 1", status: .todo, detail: "", date: .now, tags: [],
      ),
      ViewTodo(
        id: "2", owner: "u", content: "Task 2", status: .inProgress, detail: "", date: .now,
        tags: [],
      ),
      ViewTodo(
        id: "3", owner: "u", content: "Task 3", status: .done, detail: "", date: .now, tags: [],
      ),
    ],
    onTapTodo: { _ in },
  )
  .padding()
}
