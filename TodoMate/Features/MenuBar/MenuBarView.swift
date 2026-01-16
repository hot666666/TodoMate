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
  var body: some View {
    MenuBarQueryWrapper()
  }
}

// MARK: - Wrapper

private struct MenuBarQueryWrapper: View {
  @Query private var sdTodos: [SDTodo]

  init() {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: Date())
    guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
      let distantFuture = Date.distantFuture
      let predicate = #Predicate<SDTodo> { $0.date == distantFuture }
      _sdTodos = Query(filter: predicate)
      return
    }

    // Filter: Date is Today AND Not Deleted AND (Todo OR InProgress)
    // Note: Using literals/constants for status to avoid Predicate capture issues
    let splitStatus_todo = TodoStatus.todo.rawValue
    let splitStatus_inProgress = TodoStatus.inProgress.rawValue

    let predicate = #Predicate<SDTodo> { todo in
      todo.date >= startOfDay && todo.date < endOfDay && !todo.isDeleted
        && (todo.statusRawValue == splitStatus_todo
          || todo.statusRawValue == splitStatus_inProgress)
    }

    _sdTodos = Query(filter: predicate, sort: \.date)
  }

  var body: some View {
    let todos = sdTodos.map { $0.toDomain() }

    MenuBarContent(todos: todos)
  }
}

// MARK: - Content

private struct MenuBarContent: View {
  @Environment(\.openWindow) private var openWindow
  @Environment(LocalTodoHelper.self) private var todoHelper
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
              todoHelper.updateStatus(todo, status: .inProgress)
            case .inProgress:
              todoHelper.updateStatus(todo, status: .complete)
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
