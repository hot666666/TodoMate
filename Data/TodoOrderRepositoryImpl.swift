//
//  TodoOrderRepositoryImpl.swift
//  Todo
//
//  Created by hs on 7/7/25.
//

import Foundation

final class UserDefaultsTodoOrderRepository: TodoOrderRepository {
  private let userDefaults: UserDefaults

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  private func key(userId: String, dateKey: String) -> String {
    "todoOrder_\(userId)_\(dateKey)"
  }

  func saveTodoOrder(_ order: TodoOrder) {
    let key = key(userId: order.userId, dateKey: order.dateKey)
    userDefaults.set(order.todoIds, forKey: key)
  }

  func loadTodoOrder(userId: String, dateKey: String) -> TodoOrder? {
    let key = key(userId: userId, dateKey: dateKey)
    guard let todoIds = userDefaults.array(forKey: key) as? [String] else { return nil }

    return TodoOrder(
      userId: userId,
      dateKey: dateKey,
      todoIds: todoIds,
    )
  }

  func deleteTodoOrder(userId: String, dateKey: String) {
    let key = key(userId: userId, dateKey: dateKey)
    userDefaults.removeObject(forKey: key)
  }
}

final class StubTodoOrderRepository: TodoOrderRepository {
  func saveTodoOrder(_: TodoOrder) {}

  func loadTodoOrder(userId _: String, dateKey _: String) -> TodoOrder? {
    nil
  }

  func deleteTodoOrder(userId _: String, dateKey _: String) {}
}
