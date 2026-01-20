//
//  BoardViewModel.swift
//  TodoMate
//
//  Created by agent on 1/19/26.
//

import Foundation
import Observation
import TodoMateDomain

@Observable
@MainActor
final class BoardViewModel {
  // MARK: - Properties

  var dateFilter: DateFilter = .today
  var scrollPosition: BoardScrollPosition? = .leading

  private(set) var store: TodoBoardStore

  // MARK: - Initialization

  init(store: TodoBoardStore) {
    self.store = store
  }

  // MARK: - Computed Properties

  var filteredTodos: [Todo] {
    // 1. Store의 데이터는 이미 dateFilter 범위에 맞춰져 있다고 가정하거나(Store에서 fetch),
    // 2. 여기서 추가로 메모리 필터링이 필요할 수 있음.
    // 기존 로직: BoardView가 .task(id: dateFilter) { store.updateObservation(...) } 호출
    // 따라서 store.todos는 이미 필터된 범위의 투두를 가지고 있음.
    // BoardView의 logic: store.todos.map { ViewTodo }
    // 여기서는 단순히 store.todos를 반환하면 됨.
    store.todos
  }

  // MARK: - Actions

  func advanceStatus(of todo: Todo) {
    let nextStatus = todo.status.next
    update(todo, to: nextStatus)
  }

  func update(_ todo: Todo, to status: TodoStatus) {
    store.updateStatus(todo, status: status)
  }

  func duplicate(_ todo: Todo) {
    var newTodo = Todo.copy(from: todo)
    newTodo.detail = ""
    store.addTodo(newTodo)
  }

  func delete(_ todo: Todo) {
    store.deleteTodo(todo)
  }
}
