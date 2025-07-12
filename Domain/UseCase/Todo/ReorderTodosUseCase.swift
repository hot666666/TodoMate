//
//  ReorderTodosUseCase.swift
//  Todo
//
//  Created by hs on 7/7/25.
//

import Foundation

protocol ReorderTodosUseCase {
  func run(todos: [Todo], currentUserId: String, currentDate: Date, from: Int, to: Int) -> [Todo]
}

final class ReorderTodosUseCaseImpl: ReorderTodosUseCase {
  private let saveTodoOrderUseCase: SaveTodoOrderUseCase

  init(saveTodoOrderUseCase: SaveTodoOrderUseCase) {
    self.saveTodoOrderUseCase = saveTodoOrderUseCase
  }

  func run(todos: [Todo], currentUserId: String, currentDate: Date, from: Int, to: Int) -> [Todo] {
    // 본인 Todo와 다른 사람 Todo 분리
    let myTodos = todos.filter { $0.owner == currentUserId }
    let otherTodos = todos.filter { $0.owner != currentUserId }

    // 본인 Todo만 순서 변경
    var orderedMyTodos = myTodos

    // 인덱스 범위 검증
    guard from < orderedMyTodos.count, to <= orderedMyTodos.count, from != to else {
      return todos
    }

    let movedTodo = orderedMyTodos.remove(at: from)
    orderedMyTodos.insert(movedTodo, at: to > from ? to - 1 : to)

    // 변경된 순서 저장
    saveTodoOrderUseCase.run(todos: orderedMyTodos, userId: currentUserId, currentDate: currentDate)

    return orderedMyTodos + otherTodos
  }
}

final class StubReorderTodosUseCase: ReorderTodosUseCase {
  func run(todos: [Todo], currentUserId _: String, currentDate _: Date, from _: Int, to _: Int) -> [Todo] {
    todos
  }
}
