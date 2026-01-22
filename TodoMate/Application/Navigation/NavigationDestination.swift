//
//  NavigationDestination.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SwiftUI

enum NavigationDestination: Hashable, Identifiable {
  case todo
  case memo
  case settings
  case group
  case trash

  var id: String {
    switch self {
    case .todo: "todo"
    case .memo: "memo"
    case .settings: "settings"
    case .group: "group"
    case .trash: "trash"
    }
  }

  var title: String {
    switch self {
    case .todo: "Todo"
    case .memo: "Memo"
    case .settings: "Settings"
    case .group: "Group"
    case .trash: "Trash"
    }
  }
}
