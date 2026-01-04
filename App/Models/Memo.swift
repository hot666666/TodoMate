//
//  Memo.swift
//  TodoMate
//
//  Created by agent on 1/3/26.
//

import Foundation

struct Memo: Identifiable, Hashable {
  let id: UUID
  var content: String
  var date: Date

  init(id: UUID = UUID(), content: String, date: Date = Date()) {
    self.id = id
    self.content = content
    self.date = date
  }
}
