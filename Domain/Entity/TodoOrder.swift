//
//  TodoOrder.swift
//  Todo
//
//  Created by hs on 7/7/25.
//

import Foundation

struct TodoOrder {
  let userId: String
  let dateKey: String /// yearMonthDay format
  let todoIds: [String]

  init(userId: String, dateKey: String, todoIds: [String]) {
    self.userId = userId
    self.dateKey = dateKey
    self.todoIds = todoIds
  }
}
