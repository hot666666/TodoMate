//
//  MockTodoService.swift
//  TodoMate
//
//  Created by hs on 3/10/25.
//

import Foundation
@testable import TodoMate

final class MockTodoService: TodoServiceType {
  var fetchTodayResult: [Todo] = []

  func fetchTodos() async throws -> [Todo] { [] }
  func create(from todo: Todo) async -> Todo? { nil }
  func fetchMonth(userId: String, startDate: Date, endDate: Date) async -> [Date: [Todo]] { [:] }
  func fetchToday(groupId: String) async -> [Todo] { fetchTodayResult }
  func update(_ todo: Todo) {}
  func update(from todo: Todo, with newTodo: Todo) throws {}
  func remove(_ todo: Todo) {}
}

final class MockTodoOrderService: TodoOrderServiceType {
  var loadOrderResult: [String]?
  var savedOrder: [String]?
  var savedDate: Date?

  func loadOrder(for date: Date) -> [String]? { loadOrderResult }
  func saveOrder(_ order: [String], for date: Date) {
    savedOrder = order
    savedDate = Calendar.current.startOfDay(for: date)
  }
}
