//
//  MockTodoOrderRepository.swift
//  TodoMate
//
//  Created by hs on 3/10/25.
//

import Foundation
@testable import TodoMate

struct MockTodoOrderRepository: TodoOrderRepositoryType {
  // load만 테스트하기 위해 save는 더미로 구현

  var loadOrderHandler: (() -> [String])?
  var loadDateHandler: (() -> Date?)?

  func saveOrder(_ order: [String]) {}
  func saveDate(_ date: Date) {}

  func loadOrder() -> [String] {
    loadOrderHandler?() ?? []
  }

  func loadDate() -> Date? {
    loadDateHandler?()
  }
}
