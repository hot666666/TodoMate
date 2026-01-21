//
//  OverlayIdentifier+.swift
//  TodoMate
//
//  Created by agent on 1/13/26.
//

import SimpleOverlaySystem

enum OverlayIDs {
  static let todoSheet = OverlayIdentifier.unique("todoSheet")
  static let dayTodoList = OverlayIdentifier.unique("dayTodoList")
  static let discardConfirmation = OverlayIdentifier.unique("discardConfirmation")
}
