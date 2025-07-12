//
//  TodoOrderRepository.swift
//  TodoMate
//
//  Created by hs on 7/12/25.
//

protocol TodoOrderRepository {
  func saveTodoOrder(_ order: TodoOrder)
  func loadTodoOrder(userId: String, dateKey: String) -> TodoOrder?
  func deleteTodoOrder(userId: String, dateKey: String)
}
