//
//  TodoTextStyle.swift
//  TodoMate
//
//  Created by agent on 1/20/26.
//

import SwiftUI
import TodoMateDomain

// MARK: - TodoTextStyle

struct TodoTextStyleModifier: ViewModifier {
  let isDone: Bool

  func body(content: Content) -> some View {
    content
      .foregroundStyle(isDone ? .secondary : .primary)
      .strikethrough(isDone)
  }
}

extension View {
  func todoTextStyle(isDone: Bool) -> some View {
    modifier(TodoTextStyleModifier(isDone: isDone))
  }
}
