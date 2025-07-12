//
//  WidgetTodo.swift
//  Todo
//
//  Created by hs on 6/27/25.
//

import SwiftData

@Model
final class WidgetTodo: Identifiable {
  @Attribute(.unique) var id: String
  var content: String

  init(id: String, content: String) {
    self.id = id
    self.content = content
  }

  var contentOrPlaceholder: String {
    content.isEmpty ? "이름없음" : content
  }
}
