//
//  CalendarDayCell.swift
//  Todo
//
//  Created by hs on 6/25/25.
//

import SwiftUI

struct CalendarDayCell: View {
  let calendarDay: CalendarDay
  let todos: [Todo]
  let cornerPosition: CornerPosition
  let onAddTodo: (Date) -> Void
  let onMoveTodo: (String, Date, Date) -> Void
  let onCopyTodo: (Todo) -> Void
  let onDeleteTodo: (Todo) -> Void
  let onTapTodo: (Todo) -> Void

  @Environment(\.calendarCellHeight) private var cellHeight
  @State private var dropZoneState: DropZoneState = .normal

  private func handleDrop(_ draggedTodos: [DraggedTodo]) -> Bool {
    guard let draggedTodo = draggedTodos.first else { return false }

    let targetDate = calendarDay.date.startOfDay
    let sourceDate = draggedTodo.sourceDate.startOfDay

    guard targetDate != sourceDate else { return false }

    dropZoneState = .accepting

    Task {
      onMoveTodo(draggedTodo.todoId, sourceDate, targetDate)

      await MainActor.run {
        dropZoneState = .normal
      }
    }

    return true
  }

  private func handleDropTargeting(_ isTargeted: Bool) {
    dropZoneState = isTargeted ? .dragOver : .normal
  }

  var body: some View {
    ZStack {
      backgroundView
      contentView
      cellOverlay
    }
    .frame(height: cellHeight)
    .contentShape(.rect)
    .dropDestination(for: DraggedTodo.self) { draggedTodos, _ in
      handleDrop(draggedTodos)
    } isTargeted: { isTargeted in
      handleDropTargeting(isTargeted)
    }
    .contextMenu { contextMenuContent }
  }

  private var backgroundView: some View {
    UnevenRoundedRectangle(cornerRadii: cornerPosition.cornerRadii)
      .fill(calendarDay.isCurrentMonth ? Color.customBlack.opacity(0.5) : Color.customDarkBg.opacity(0.6))
  }

  private var contentView: some View {
    VStack(spacing: 8) {
      dateView
      todoListView
    }
  }

  private var dateView: some View {
    HStack {
      Spacer()
      ZStack(alignment: .center) {
        if calendarDay.date.isToday {
          Circle()
            .fill(Color.secondary.opacity(0.2))
            .frame(width: 24, height: 24)
        }

        Text("\(calendarDay.day)")
          .font(.system(size: 14, weight: dateWeight, design: .rounded))
          .foregroundStyle(calendarDay.date.isToday ? .primary : dateColor)
      }
      .frame(width: 24, height: 24)
      .padding(.trailing, 8)
      .padding(.top, 6)
    }
    .frame(height: 26)
  }

  private var todoListView: some View {
    VStack(alignment: .leading, spacing: 5) {
      ForEach(Array(todos.prefix(maxTodosForHeight).enumerated()), id: \.offset) { _, todo in
        CalendarDayTodoItem(todo: todo, sourceDate: calendarDay.date)
          .frame(height: 16)
          .onTapGesture { onTapTodo(todo) }
          .contextMenu {
            Button("복제") { onCopyTodo(todo) }
            DeleteContextMenuButton(todo: todo, onDelete: onDeleteTodo)
          }
      }

      if todos.count > maxTodosForHeight {
        Text("+ \(todos.count - maxTodosForHeight)개...")
          .font(.caption2)
          .foregroundColor(.secondary)
          .padding(.horizontal, 4)
          .frame(height: 16)
          .frame(maxWidth: .infinity, alignment: .leading)
      }

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 2)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }

  private var contextMenuContent: some View {
    Button("추가") {
      onAddTodo(calendarDay.date)
    }
  }

  private var cellOverlay: some View {
    ZStack {
      if dropZoneState != .normal {
        overlayForDropState
      }
    }
  }

  @ViewBuilder
  private var overlayForDropState: some View {
    switch dropZoneState {
    case .dragOver:
      UnevenRoundedRectangle(cornerRadii: cornerPosition.cornerRadii)
        .inset(by: 1)
        .stroke(
          LinearGradient(
            colors: [.secondary.opacity(0.8), .secondary.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 2
        )
        .shadow(color: .secondary.opacity(0.2), radius: 4, x: 0, y: 1)
    case .accepting:
      UnevenRoundedRectangle(cornerRadii: cornerPosition.cornerRadii)
        .fill(
          LinearGradient(
            colors: [.secondary.opacity(0.15), .secondary.opacity(0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .overlay(
          UnevenRoundedRectangle(cornerRadii: cornerPosition.cornerRadii)
            .inset(by: 1)
            .stroke(.secondary.opacity(0.8), lineWidth: 2)
        )
        .shadow(color: .secondary.opacity(0.2), radius: 4, x: 0, y: 1)
    case .normal:
      EmptyView()
    }
  }

  private var dateWeight: Font.Weight {
    calendarDay.date.isToday ? .bold : (calendarDay.isCurrentMonth ? .medium : .regular)
  }

  private var dateColor: Color {
    if calendarDay.date.isToday {
      .accentColor
    } else if calendarDay.isCurrentMonth {
      .primary
    } else {
      .secondary.opacity(0.5)
    }
  }

  private var maxTodosForHeight: Int {
    // 실제 코드 값들로 정확한 계산
    let dateAreaHeight: CGFloat = 26 // dateView.frame(height: 26) - 동그란 오버레이 고려하여 증가
    let contentSpacing: CGFloat = 8 // VStack(spacing: 8)
    let todoItemHeight: CGFloat = 16 // CalendarDayTodoItem.frame(height: 16)
    let todoItemSpacing: CGFloat = 5 // VStack(spacing: 5) in todoListView
    let moreTextHeight: CGFloat = 16 // "+ X개..." .frame(height: 16) - 아이템과 동일
    let safetyMargin: CGFloat = 6 // 안전 마진 증가

    let fixedHeight = dateAreaHeight + contentSpacing + safetyMargin
    let availableContentHeight = cellHeight - fixedHeight

    // 할일이 없으면 0 반환
    guard !todos.isEmpty else { return 0 }

    // 모든 할일이 들어갈 수 있는지 먼저 확인
    let totalItemsHeight = CGFloat(todos.count) * todoItemHeight + CGFloat(max(0, todos.count - 1)) * todoItemSpacing

    if totalItemsHeight <= availableContentHeight {
      return todos.count // 모든 할일 표시 가능
    }

    // "+ X개..." 텍스트가 필요한 경우의 최소 공간 확인
    let minSpaceForMore = moreTextHeight + todoItemSpacing
    if availableContentHeight < minSpaceForMore {
      return 0 // 생략 텍스트조차 표시할 공간이 없음
    }

    // "+ X개..." 텍스트가 필요한 경우
    let availableForItemsWithMore = availableContentHeight - moreTextHeight - todoItemSpacing
    let maxVisibleItems = Int(floor(availableForItemsWithMore / (todoItemHeight + todoItemSpacing)))

    return max(0, maxVisibleItems) // 0개도 허용
  }
}

extension CalendarDayCell {
  enum DropZoneState {
    case normal
    case dragOver
    case accepting
  }
}
