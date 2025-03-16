//
//  StubFirestore.swift
//  TodoMate
//
//  Created by hs on 3/15/25.
//

import Foundation

// PREVIEW 용 Firestore
final class StubFirestore {
  /// AsyncStream에서 전달받은 continuation을 저장하는 프로퍼티, 단일 구독자용
  private(set) var continuation: AsyncStream<DatabaseChange<TodoDTO>>.Continuation?
  private(set) var todos: [TodoDTO] = []

  //    private var users: [UserDTO] = []
  //    private var chats: [ChatDTO] = []
  //    private var groups: [GroupDTO] = []

  init() {}

  func todoStream() -> AsyncStream<DatabaseChange<TodoDTO>> {
    AsyncStream { continuation in
      /// 구독 시 기존 todos 상태를 초기 이벤트로 전달
      self.todos.forEach { continuation.yield(.added($0)) }

      self.continuation = continuation
    }
  }

  func todoStreamTermination() {
    continuation?.finish()
    continuation = nil
  }

  func create(todo: TodoDTO) throws -> TodoDTO {
    var newTodo = todo
    newTodo.id = UUID().uuidString

    todos.append(newTodo)

    continuation?.yield(.added(newTodo))

    return newTodo
  }

  func read() -> [TodoDTO] {
    return todos
  }

  func update(todo: TodoDTO) throws {
    guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
    todos[index] = todo

    continuation?.yield(.modified(todo))
  }

  func delete(todoId: String) throws {
    guard let index = todos.firstIndex(where: { $0.id == todoId }) else { return }

    let todo = todos.remove(at: index)

    continuation?.yield(.removed(todo))
  }
}
