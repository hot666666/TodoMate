//
//  SidebarSelection.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SwiftUI

enum SidebarSelection: Hashable, Identifiable {
  case todo
  case memo
  case settings
  case group(String) // Group ID
  case noGroups

  var id: Self { self }

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
