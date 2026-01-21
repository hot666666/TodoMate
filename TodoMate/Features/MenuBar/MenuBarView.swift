//
//  MenuBarView.swift
//  TodoMate
//
//  Created by hs on 6/7/25.
//
//

import AppKit
import Common
import SwiftData
import SwiftUI
import TodoMateDomain

struct MenuBarView: View {
  @Environment(TodoBoardStore.self) private var todoStore

  private var todayTodos: [Todo] {
    let calendar = Calendar.current
    return todoStore.todos.filter {
      calendar.isDateInToday($0.date) && !$0.isDeleted
        && ($0.status == .todo || $0.status == .inProgress)
    }
    .sorted { $0.date < $1.date }
  }

  var body: some View {
    MenuBarContent(todos: todayTodos)
  }
}

// MARK: - Content

private struct MenuBarContent: View {
  @Environment(\.openWindow) private var openWindow
  @Environment(TodoBoardStore.self) private var todoStore
  let todos: [Todo]

  var body: some View {
    // 1. 새 할일 (Opens Main App)
    Button("새 할일") {
      openWindow(id: AppSceneID.mainApp.rawValue)
    }
    .keyboardShortcut(" ", modifiers: [.command, .shift])

    // 2. 앱 열기
    Button("TodoMate 열기") {
      openWindow(id: AppSceneID.mainApp.rawValue)
    }
    .keyboardShortcut("O", modifiers: [.command])

    Divider()

    // 3. 오늘 할일 목록
    Section {
      if todos.isEmpty {
        Text("오늘 할일 없음")
          .foregroundStyle(.secondary)
      } else {
        ForEach(todos) { todo in
          MenuTodoRow(todo: todo) { todo in
            switch todo.status {
            case .todo:
              todoStore.updateStatus(todo, status: .inProgress)
            case .inProgress:
              todoStore.updateStatus(todo, status: .complete)
            default:
              break
            }
          }
        }
      }
    } header: {
      Text("오늘의 할일")
    }

    Divider()

    // 4. 종료
    Button("종료") {
      NSApplication.shared.terminate(nil)
    }
    .keyboardShortcut("Q", modifiers: [.command])
  }
}

// MARK: - MenuTodoRow

private struct MenuTodoRow: View {
  let todo: Todo
  let action: (Todo) -> Void

  var body: some View {
    HStack(spacing: 4) {
      Button {
        action(todo)
      } label: {
        Image(systemName: todo.status.iconName)
        Text(todo.content.isEmpty ? "제목 없음" : todo.content)
          .lineLimit(1)
      }
    }
  }
}
