//
//  ShortcutAction.swift
//  TodoMate
//
//  Created by hs on 3/10/25.
//

import SwiftUI

enum ShortcutAction: String {
  case createUserTodo
  case closeOverlay
}

extension Notification.Name {
  static let shortcutAction = Notification.Name("todoMateShortcutAction")
}
