//
//  NavigationDestination.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SwiftUI

enum NavigationDestination: Hashable, Identifiable {
  case todo(ContentViewMode? = nil)
  case memo
  case settings
  case group(String) // Group ID
  case noGroups

  var id: String {
    switch self {
    case .todo: "todo"
    case .memo: "memo"
    case .settings: "settings"
    case let .group(id): "group_\(id)"
    case .noGroups: "noGroups"
    }
  }

  var title: String {
    switch self {
    case .todo: "Todo"
    case .memo: "Memo"
    case .settings: "Settings"
    case let .group(groupId): groupId
    case .noGroups: "No Groups Joined"
    }
  }
}
