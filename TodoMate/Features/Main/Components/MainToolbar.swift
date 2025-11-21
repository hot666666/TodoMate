//
//  MainToolbar.swift
//  TodoMate
//
//  Created by hs on 7/21/25.
//

import SwiftUI

/// MainView의 툴바 컴포넌트
struct MainToolbar: ToolbarContent {
  let hasUnreadMessages: Bool
  let onRefresh: () -> Void
  let onAddTodo: () -> Void
  let onShowCalendar: () -> Void
  let onToggleMessage: () -> Void

  var body: some ToolbarContent {
    ToolbarItemGroup(placement: .primaryAction) {
      RefreshButton(action: onRefresh)
      Spacer()
      HStack(spacing: 8) {
        AddTodoButton(action: onAddTodo)
        CalendarButton(action: onShowCalendar)
        MessageButton(hasUnread: hasUnreadMessages, action: onToggleMessage)
      }
    }
  }
}

// MARK: - Toolbar Buttons

private struct RefreshButton: View {
  let action: () -> Void

  var body: some View {
    Button("새로고침", systemImage: "arrow.clockwise", action: action)
      .keyboardShortcut("r", modifiers: .command)
  }
}

private struct AddTodoButton: View {
  let action: () -> Void

  var body: some View {
    Button("새 할일", systemImage: "plus", action: action)
      .keyboardShortcut("n", modifiers: .command)
  }
}

private struct CalendarButton: View {
  let action: () -> Void

  var body: some View {
    Button("달력", systemImage: "calendar", action: action)
      .keyboardShortcut("a", modifiers: .command)
  }
}

private struct MessageButton: View {
  let hasUnread: Bool
  let action: () -> Void

  var body: some View {
    Button("메시지", systemImage: hasUnread ? "bubble.right.fill" : "bubble.right", action: action)
      .keyboardShortcut("i", modifiers: .command)
  }
}
