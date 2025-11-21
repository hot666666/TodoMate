//
//  TodoContextMenu.swift
//  TodoMate
//
//  Created by hs on 7/21/25.
//

import SwiftUI

/// Todo 아이템의 컨텍스트 메뉴를 제공하는 재사용 가능한 컴포넌트
struct TodoContextMenu: View {
  let todo: Todo
  let showCopy: Bool
  let showDelete: Bool
  let onCopy: ((Todo) -> Void)?
  let onDelete: ((Todo) -> Void)?

  init(
    todo: Todo,
    showCopy: Bool = false,
    showDelete: Bool = true,
    onCopy: ((Todo) -> Void)? = nil,
    onDelete: ((Todo) -> Void)? = nil
  ) {
    self.todo = todo
    self.showCopy = showCopy
    self.showDelete = showDelete
    self.onCopy = onCopy
    self.onDelete = onDelete
  }

  var body: some View {
    Group {
      if showCopy, let onCopy {
        Button("복제") {
          onCopy(todo)
        }
      }

      if showDelete, let onDelete {
        Button("삭제", role: .destructive) {
          onDelete(todo)
        }
      }
    }
  }
}

// MARK: - ViewModifier for Context Menu

struct TodoContextMenuModifier: ViewModifier {
  let todo: Todo
  let showCopy: Bool
  let showDelete: Bool
  let onCopy: ((Todo) -> Void)?
  let onDelete: ((Todo) -> Void)?

  func body(content: Content) -> some View {
    content
      .contextMenu {
        TodoContextMenu(
          todo: todo,
          showCopy: showCopy,
          showDelete: showDelete,
          onCopy: onCopy,
          onDelete: onDelete
        )
      }
  }
}

extension View {
  /// Todo 컨텍스트 메뉴를 추가합니다.
  func todoContextMenu(
    for todo: Todo,
    showCopy: Bool = false,
    showDelete: Bool = true,
    onCopy: ((Todo) -> Void)? = nil,
    onDelete: ((Todo) -> Void)? = nil
  ) -> some View {
    modifier(TodoContextMenuModifier(
      todo: todo,
      showCopy: showCopy,
      showDelete: showDelete,
      onCopy: onCopy,
      onDelete: onDelete
    ))
  }
}
