//
//  ApplyTodoOrderUseCase.swift
//  Todo
//
//  Created by hs on 7/7/25.
//

import Foundation

protocol ApplyTodoOrderUseCase {
  func run(todos: [Todo], currentUserId: String, currentDate: Date) -> [Todo]
}

final class ApplyTodoOrderUseCaseImpl: ApplyTodoOrderUseCase {
  private let orderRepository: TodoOrderRepository
  private let saveTodoOrderUseCase: SaveTodoOrderUseCase

  init(orderRepository: TodoOrderRepository, saveTodoOrderUseCase: SaveTodoOrderUseCase) {
    self.orderRepository = orderRepository
    self.saveTodoOrderUseCase = saveTodoOrderUseCase
  }

  func run(todos: [Todo], currentUserId: String, currentDate: Date) -> [Todo] {
    // 본인 Todo와 다른 사람 Todo 분리
    let myTodos = todos.filter { $0.owner == currentUserId }
    let otherTodos = todos.filter { $0.owner != currentUserId }

    let dateKey = currentDate.startOfDay.yearMonthDay

    // 본인 Todo에만 순서 캐시 적용
    if let cachedOrder = orderRepository.loadTodoOrder(userId: currentUserId, dateKey: dateKey) {
      let orderedMyTodos = applyOrder(todos: myTodos, order: cachedOrder.todoIds)
      return orderedMyTodos + otherTodos
    } else {
      // 캐시가 없으면 현재 순서 저장
      saveTodoOrderUseCase.run(todos: myTodos, userId: currentUserId, currentDate: currentDate)
      return todos
    }
  }

  private func applyOrder(todos: [Todo], order: [String]) -> [Todo] {
    // order 배열 순서대로 Todo 정렬
    let todoDict = Dictionary(uniqueKeysWithValues: todos.map { ($0.id, $0) })
    let orderedTodos = order.compactMap { todoDict[$0] }

    // order에 없는 새로운 Todo들은 끝에 추가
    let orderedIds = Set(order)
    let newTodos = todos.filter { !orderedIds.contains($0.id) }

    return orderedTodos + newTodos
  }
}

final class StubApplyTodoOrderUseCase: ApplyTodoOrderUseCase {
  func run(todos: [Todo], currentUserId _: String, currentDate _: Date) -> [Todo] {
    todos
  }
}
