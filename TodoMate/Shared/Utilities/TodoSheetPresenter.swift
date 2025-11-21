//
//  TodoSheetPresenter.swift
//  TodoMate
//
//  Created by hs on 7/21/25.
//

import SwiftUI

/// TodoSheet을 표시하는 로직을 캡슐화한 헬퍼
struct TodoSheetPresenter {
  let overlayManager: OverlayManager

  /// 새로운 할일 추가 시트를 표시합니다.
  func presentAddSheet(for userId: String) {
    let editableTodo = EditableTodo(owner: userId)
    overlayManager.presentSheet(editableTodo: editableTodo) {
      TodoSheet(editableTodo: editableTodo)
    }
  }

  /// 기존 할일 편집 시트를 표시합니다.
  func presentEditSheet(for todo: Todo, onDismiss: (() -> Void)? = nil) {
    let editableTodo = EditableTodo(from: todo)
    overlayManager.presentSheet(
      editableTodo: editableTodo,
      onDismiss: {
        if let onDismiss, editableTodo.isDirty {
          onDismiss()
        }
      }
    ) {
      TodoSheet(editableTodo: editableTodo)
    }
  }
}

// MARK: - View Extension

extension View {
  /// TodoSheet을 표시할 수 있는 헬퍼를 제공합니다.
  func todoSheetPresenter(_ overlayManager: OverlayManager) -> TodoSheetPresenter {
    TodoSheetPresenter(overlayManager: overlayManager)
  }
}
