//
//  MenuBarView.swift
//  TodoMate
//
//  Created by hs on 6/7/25.
//
//

import AppKit
import Common
import SwiftUI
import TodoMateDomain

struct MenuBarView: View {
  // MARK: - Properties

  @Environment(TodoBoardStore.self) private var todoStore

  private var todayTodos: [Todo] {
    todoStore.todos.filter {
      $0.date.isToday && !$0.isDeleted && ($0.status == .todo || $0.status == .inProgress)
    }
    .sorted { $0.date < $1.date }
  }

  // MARK: - Body

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
    Group {
      Button("새 할일") {
        WindowManager.shared.toggleOverlay()
      }
      .keyboardShortcut(" ", modifiers: [.command, .shift])

      Button("TodoMate 열기") {
        openWindow(id: AppSceneID.mainApp.rawValue)
        NSApp.activate(ignoringOtherApps: true)
      }
      .keyboardShortcut("O", modifiers: [.command])

      Divider()

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

      Button("종료") {
        NSApplication.shared.terminate(nil)
      }
      .keyboardShortcut("Q", modifiers: [.command])
    }
    .onAppear {
      // MenuBarExtra는 앱 시작 시 항상 나타나므로 여기서 주입
      WindowManager.shared.openWindowAction = openWindow
    }
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
