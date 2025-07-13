//
//  SaveTodoOrderUseCase.swift
//  Todo
//
//  Created by hs on 7/7/25.
//

import Foundation

protocol SaveTodoOrderUseCase {
  func run(todos: [Todo], userId: String, currentDate: Date)
}

final class SaveTodoOrderUseCaseImpl: SaveTodoOrderUseCase {
  private let orderRepository: TodoOrderRepository

  init(orderRepository: TodoOrderRepository) {
    self.orderRepository = orderRepository
  }

  func run(todos: [Todo], userId: String, currentDate: Date) {
    let todoIds = todos.map(\.id)
    let dateKey = currentDate.startOfDay.yearMonthDay
    let order = TodoOrder(
      userId: userId,
      dateKey: dateKey,
      todoIds: todoIds
    )
    orderRepository.saveTodoOrder(order)
  }
}

final class StubSaveTodoOrderUseCase: SaveTodoOrderUseCase {
  func run(todos _: [Todo], userId _: String, currentDate _: Date) {}
}
