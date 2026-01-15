//
//  MenuBarView.swift
//  TodoMate
//
//  Created by hs on 6/7/25.
//

import AppKit
import Common
import SwiftData
import SwiftUI
import TodoMateDomain

struct MenuBarView: View {
  @Environment(\.openWindow) private var openWindow
  @Environment(PrivateTodoStore.self) private var todoStore

  let onShowOverlay: (Todo?) -> Void

  var body: some View {
    // 1. 새 할일
    Button("새 할일") {
      onShowOverlay(nil)
    }
    .keyboardShortcut(" ", modifiers: [.command, .shift])

    // 2. 앱 열기
    Button("TodoMate 열기") {
      // Main Window 열기 (WindowGroup id 확인 필요, 보통 main or nil)
      // TodoMateApp에서 WindowGroup에 handlesExternalEvents 설정이 필요할 수 있음
      // 현재는 openWindow로 시도
      NSApp.activate(ignoringOtherApps: true)
      // 첫 번째 윈도우(메인)를 보이게 함
      if let window = NSApp.windows.first {
        window.makeKeyAndOrderFront(nil)
      }
    }

    Divider()

    // 3. 오늘 할일 목록 (미완료/진행중 우선)
    Section {
      let activeTodos = todoStore.todos.filter { $0.status == .todo || $0.status == .inProgress }

      if activeTodos.isEmpty {
        Text("오늘 할일 없음")
          .foregroundStyle(.secondary)
      } else {
        ForEach(activeTodos) { todo in
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

  private var statusColor: Color {
    switch todo.status {
    case .inComplete: .red
    case .todo: .secondary
    case .inProgress: .blue
    case .complete: .green
    }
  }

  var body: some View {
    Button {
      onShowOverlay(todo)
    } label: {
      HStack(spacing: 4) {
        Image(systemName: statusIcon)
        // MenuBarExtra style .menu does not support color rendering well in standard menu items
        // but we try. If it doesn't show, it falls back to monochrome.
        Text(todo.content.isEmpty ? "제목 없음" : todo.content)
          .lineLimit(1)
      }
    }
  }
}
