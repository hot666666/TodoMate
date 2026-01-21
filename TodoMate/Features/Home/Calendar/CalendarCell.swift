//
//  CalendarCell.swift
//  TodoMate
//
//  Created by agent on 1/21/26.
//

import SwiftUI
import TodoMateDomain

/// 캘린더 그리드의 개별 날짜 셀
struct CalendarCell: View {
  // MARK: - Properties

  let date: Date
  let cellHeight: CGFloat
  let todos: [Todo]
  let isToday: Bool
  let isCurrentMonth: Bool

  // MARK: - Computed Properties

  private var maxVisibleItems: Int {
    let availableHeight = cellHeight - 30
    return max(0, Int(availableHeight / 26))
  }

  // MARK: - Body

  var body: some View {
    let visibleTodos = todos.prefix(maxVisibleItems)
    let hiddenCount = max(0, todos.count - maxVisibleItems)

    VStack(alignment: .leading, spacing: 2) {
      // Date Number
      Text(date.formatted(.dateTime.day()))
        .font(.caption)
        .fontWeight(isToday ? .heavy : .regular)
        .foregroundStyle(isCurrentMonth ? .primary : .secondary)
        .padding([.top, .leading], 6)

      // Todo List
      ForEach(visibleTodos) { todo in
        CalendarTodoCard(todo: todo)
          .padding(.horizontal, 2)
      }

      // More Indicator
      if hiddenCount > 0 {
        Text("+\(hiddenCount) more")
          .font(.caption2)
          .foregroundStyle(.secondary)
          .padding(.leading, 6)
          .padding(.bottom, 4)
      }

      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, alignment: .topLeading)
    .background(
      Rectangle()
        .fill(
          isToday
            ? Color.accentColor.opacity(0.05)
            : Color(nsColor: .controlBackgroundColor).opacity(isCurrentMonth ? 0.5 : 0.2),
        ),
    )
    .border(Color.gray.opacity(0.1), width: 0.5)
    .contentShape(.rect)
  }
}
