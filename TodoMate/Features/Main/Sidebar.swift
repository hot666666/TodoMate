//
//  Sidebar.swift
//  TodoMate
//
//  Created by hs on 7/14/25.
//

enum Sidebar: Identifiable, Hashable, Equatable {
  case profile
  case user(User)

  var id: String {
    switch self {
    case .profile:
      "profile"
    case let .user(user):
      "user_\(user.id)"
    }
  }

  var title: String {
    switch self {
    case .profile:
      "계정"
    case let .user(user):
      user.displayName
    }
  }
}
