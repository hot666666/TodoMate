//
//  DayTodoList.swift
//  TodoMate
//
//  Created by agent on 1/7/26.
//

import SimpleOverlaySystem
import SwiftUI
import TodoMateDomain

/// 특정 날짜의 모든 할 일 목록을 4열 상태별 레이아웃으로 보여주는 오버레이 뷰
struct DayTodoList: View {
  // MARK: - Environment

  @Environment(\.overlayManager) private var overlay
  @Environment(TodoCalendarViewModel.self) private var viewModel

  // MARK: - Properties

  let date: Date

  // MARK: - Computed Properties

  private var todos: [Todo] { viewModel.selectedDateTodos }

  private var title: String {
    date.formatted(.dateTime.month().day().weekday(.wide))
  }

  // MARK: - Body

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      header
      content
    }
    .padding(20)
    .frame(width: 900, height: 500)
    .materialCardOverlay()
    .onKeyPress(.escape) {
      overlay?.dismissTop()
      return .handled
    }
    .onGlobalHotKey(.escape) {
      overlay?.dismissTop()
    }
  }

  private var header: some View {
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
  }

  @ViewBuilder
  private var content: some View {
    if todos.isEmpty {
      Text("이 날짜에 등록된 일정이 없습니다.")
        .font(.body)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    } else {
      HStack(alignment: .top, spacing: 16) {
        ForEach(TodoStatus.allCases, id: \.self) { status in
          statusColumn(for: status)
        }
      }
    }
  }

  private func statusColumn(for status: TodoStatus) -> some View {
    let filteredTodos = todos.filter { $0.status == status }

    return TodoColumnView(
      title: status.displayName, count: filteredTodos.count, color: status.displayColor,
    ) {
      ScrollView(.vertical, showsIndicators: false) {
        LazyVStack(spacing: 2) {
          ForEach(filteredTodos) { todo in
            CalendarTodoCard(todo: todo)
              .draggable(todo)
          }
        }
        .padding(2)
      }
      .contentMargins(.bottom, 16, for: .scrollContent)
    }
    .frame(maxWidth: .infinity)
    .dropDestination(for: Todo.self) { items, _ in
      viewModel.handleStatusDrop(todos: items, to: status)
    }
  }
}

#Preview {
  DayTodoList(date: Date())
    .environment(TodoCalendarViewModel.preview)
    .environment(OverlayManager())
    .padding()
}
