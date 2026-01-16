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
  let onShowOverlay: (Todo?) -> Void

  var body: some View {
    MenuBarQueryWrapper(onShowOverlay: onShowOverlay)
  }
}

// MARK: - Wrapper

private struct MenuBarQueryWrapper: View {
  @Environment(\.openWindow) private var openWindow
  @Query private var sdTodos: [SDTodo]

  let onShowOverlay: (Todo?) -> Void

  init(onShowOverlay: @escaping (Todo?) -> Void) {
    self.onShowOverlay = onShowOverlay

    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: Date())
    guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
      let distantFuture = Date.distantFuture
      let predicate = #Predicate<SDTodo> { $0.date == distantFuture }
      _sdTodos = Query(filter: predicate)
      return
    }

    // Filter: Date is Today AND Not Deleted
    let predicate = #Predicate<SDTodo> { todo in
      todo.date >= startOfDay && todo.date < endOfDay && !todo.isDeleted
    }

    _sdTodos = Query(filter: predicate, sort: \.date)
  }

  var body: some View {
    let todos =
      sdTodos
        .map { $0.toDomain() }
        .filter { $0.status == .todo || $0.status == .inProgress }

    MenuBarContent(todos: todos, onShowOverlay: onShowOverlay)
  }
}

// MARK: - Content

private struct MenuBarContent: View {
  @Environment(\.openWindow) private var openWindow
  let todos: [Todo]
  let onShowOverlay: (Todo?) -> Void

  var body: some View {
    // 1. 새 할일
    Button("새 할일") {
      onShowOverlay(nil)
    }
    .keyboardShortcut(" ", modifiers: [.command, .shift])

    // 2. 앱 열기
    Button("TodoMate 열기") {
      openWindow(id: AppSceneID.mainApp.rawValue)
    }

    Divider()

    // 3. 오늘 할일 목록
    Section {
      if todos.isEmpty {
        Text("오늘 할일 없음")
          .foregroundStyle(.secondary)
      } else {
        ForEach(todos) { todo in
          MenuTodoRow(todo: todo, onShowOverlay: onShowOverlay)
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
  }
}

// MARK: - MenuTodoRow

private struct MenuTodoRow: View {
  let todo: Todo
  let onShowOverlay: (Todo?) -> Void

  private var statusIcon: String {
    switch todo.status {
    case .inComplete:
      "exclamationmark.circle"
    case .todo:
      "circle"
    case .inProgress:
      "circle.fill"
    case .complete:
      "checkmark.circle"
    }
  }

  var body: some View {
    Button {
      onShowOverlay(todo)
    } label: {
      HStack(spacing: 4) {
        Image(systemName: statusIcon)
        Text(todo.content.isEmpty ? "제목 없음" : todo.content)
          .lineLimit(1)
      }
    }
  }
}
