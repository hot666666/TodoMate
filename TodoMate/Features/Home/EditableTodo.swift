//
//  EditableTodo.swift
//  Todo
//
//  Created by hs on 6/7/25.
//

import SwiftUI

@Observable
class EditableTodo: Identifiable {
  // 원본 Todo 기록
  var originalTodo: Todo?
  // 새 Todo인지 여부
  var isNew: Bool { originalTodo == nil }
  // Todo 속성
  var id: String = UUID().uuidString
  var content: String = ""
  var detail: String = ""
  var status: TodoStatus = .todo
  var date: Date = .now
  var createdAt: Date = .now
  // Todo 작성자
  var owner: String

  init(from currentTodo: Todo) {
    // 기존 Todo 기록
    originalTodo = currentTodo
    // 기존 Todo 속성을 복사
    id = currentTodo.id
    content = currentTodo.content
    detail = currentTodo.detail
    status = currentTodo.status
    date = currentTodo.date
    createdAt = currentTodo.createdAt
    owner = currentTodo.owner
  }

  // 새로 생성하는 경우 사용
  init(owner: String) {
    self.owner = owner
  }

  var isDirty: Bool {
    // 새로 생성한 경우
    guard let original = originalTodo else {
      return !content.isEmpty || !detail.isEmpty
    }
    // 기존 내용이 존재하는 경우
    return content != original.content
      || detail != original.detail
      || status != original.status
      || date != original.date
  }
}

extension EditableTodo {
  static let stub = EditableTodo(from: Todo.stub)
}

extension Todo {
  static func from(_ editable: EditableTodo) -> Todo {
    Todo(
      id: editable.id,
      content: editable.content,
      status: editable.status,
      detail: editable.detail,
      date: editable.date,
      createdAt: editable.createdAt,
      updatedAt: editable.isNew ? editable.createdAt : .now,
      owner: editable.owner
    )
  }
}
